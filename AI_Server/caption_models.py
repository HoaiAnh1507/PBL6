"""
Video Caption Generation Models
Extracted from interactive_caption.py for queue worker usage
"""

import os
import json
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing.text import tokenizer_from_json
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow.keras import layers, models
import torch
import cv2
from PIL import Image
import open_clip
import time
from config import MODEL_WEIGHTS_PATH, TOKENIZER_PATH, BEAM_SIZE, DEVICE_PREFERENCE

# Disable TensorFlow logs
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"
tf.config.optimizer.set_jit(True)


class VideoCaptionGenerator:
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.clip_model = None
        self.preprocess = None
        self.device = None
        self.idx2word = None
        self.start_idx = None
        self.end_idx = None
        self.max_len = 47
        self.vocab_size = 10364

    def initialize(self):
        """Initialize all models (call once at startup)"""
        print("\n⏳ Initializing AI models...")
        init_start = time.time()

        # 1. Load TensorFlow model
        print("  [1/4] Loading TensorFlow model...")
        self.model = self._build_model()
        self.model.load_weights(MODEL_WEIGHTS_PATH)
        self.model.compile(optimizer="adam", loss="sparse_categorical_crossentropy")

        # 2. Load tokenizer
        print("  [2/4] Loading tokenizer...")
        with open(TOKENIZER_PATH, "r") as f:
            self.tokenizer = tokenizer_from_json(f.read())

        # Setup special tokens
        SPECIAL = {"start": "startseq", "end": "endseq"}
        self.start_idx = self.tokenizer.word_index[SPECIAL["start"]]
        self.end_idx = self.tokenizer.word_index[SPECIAL["end"]]

        # Pre-build idx2word for decoding
        self.idx2word = {i: w for w, i in self.tokenizer.word_index.items()}
        self.idx2word[0] = "<pad>"

        # 3. Load CLIP model
        print("  [3/4] Loading CLIP model...")
        self.device = self._detect_device()
        self.clip_model, self.preprocess, _ = open_clip.create_model_and_transforms(
            "ViT-L-14-336", pretrained="openai", force_quick_gelu=True
        )
        self.clip_model = self.clip_model.to(self.device).eval()

        init_time = time.time() - init_start
        print(f"✅ Models initialized! ({init_time:.2f}s)")

    def _detect_device(self):
        """Auto-detect best available device"""
        if DEVICE_PREFERENCE != "auto":
            return DEVICE_PREFERENCE

        if torch.cuda.is_available():
            device = "cuda"
            device_name = f"CUDA GPU: {torch.cuda.get_device_name(0)}"
        elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            device = "mps"
            device_name = "Apple Silicon GPU (MPS)"
        else:
            device = "cpu"
            device_name = "CPU"

        print(f"  [4/4] Device: {device_name}")
        return device

    def _build_model(self, feat_dim=768):
        """Rebuild the exact model architecture"""
        vi = layers.Input(shape=(feat_dim,), name="visual")
        vb = layers.Dense(256, activation="relu")(vi)
        vb = layers.Dropout(0.5)(vb)

        si = layers.Input(shape=(self.max_len,), name="seq_in")
        emb = layers.Embedding(
            input_dim=self.vocab_size, output_dim=256, mask_zero=True
        )(si)
        lstm = layers.LSTM(256)(emb)

        fusion = layers.Add()([vb, lstm])
        hd = layers.Dense(256, activation="relu")(fusion)
        out = layers.Dense(self.vocab_size)(hd)

        model = models.Model(inputs=[vi, si], outputs=out)
        return model

    def extract_video_features(self, video_path):
        """Extract visual features from video using CLIP"""
        if not os.path.exists(video_path):
            raise FileNotFoundError(f"Video file not found: {video_path}")

        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError(f"Cannot open video: {video_path}")

        frames = []
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

        # Sample frames evenly (max 8 frames)
        sample_interval = max(1, frame_count // 8)

        for i in range(0, frame_count, sample_interval):
            cap.set(cv2.CAP_PROP_POS_FRAMES, i)
            ret, frame = cap.read()
            if ret:
                # Convert BGR to RGB
                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                pil_image = Image.fromarray(frame_rgb)
                frames.append(self.preprocess(pil_image))

        cap.release()

        if not frames:
            raise ValueError("No frames extracted from video")

        # Process frames through CLIP
        frames_tensor = torch.stack(frames).to(self.device)

        with torch.no_grad():
            features = self.clip_model.encode_image(frames_tensor)
            # Average pool features across frames
            pooled_features = features.mean(dim=0)

        return pooled_features.cpu().numpy()

    def generate_caption(self, video_feature, beam_size=None):
        """Generate caption using optimized beam search (from interactive_caption.py)"""
        if beam_size is None:
            beam_size = BEAM_SIZE

        beams = [([self.start_idx], 0.0)]

        for step in range(self.max_len - 1):
            candidates = []

            for seq, score in beams:
                if seq[-1] == self.end_idx:
                    candidates.append((seq, score, None))
                else:
                    candidates.append((seq, score, seq))

            active_seqs = [c[2] for c in candidates if c[2] is not None]

            if not active_seqs:
                break

            # Batch prediction
            batch_in_seqs = np.array(
                [
                    pad_sequences([seq], maxlen=self.max_len, padding="post")[0]
                    for seq in active_seqs
                ]
            )
            batch_video_feats = np.repeat(
                video_feature[np.newaxis, :], len(active_seqs), axis=0
            )

            logits_batch = self.model.predict(
                [batch_video_feats, batch_in_seqs],
                verbose=0,
                batch_size=len(active_seqs),
            )
            probs_batch = tf.nn.softmax(logits_batch).numpy()

            new_beams = []
            active_idx = 0

            for seq, score, active_seq in candidates:
                if active_seq is None:
                    new_beams.append((seq, score))
                else:
                    probs = probs_batch[active_idx]
                    active_idx += 1

                    k = min(beam_size, len(probs))
                    topk_ids = np.argpartition(probs, -k)[-k:]
                    topk_ids = topk_ids[np.argsort(probs[topk_ids])[::-1]]

                    for word_id in topk_ids:
                        new_seq = seq + [int(word_id)]
                        new_score = score + np.log(probs[word_id] + 1e-9)
                        new_beams.append((new_seq, new_score))

            new_beams.sort(key=lambda x: x[1], reverse=True)
            beams = new_beams[:beam_size]

            if all(s[-1] == self.end_idx for s, _ in beams):
                break

        # Return best sequence
        best_seq = beams[0][0]
        words = [
            self.idx2word.get(word_id, "")
            for word_id in best_seq[1:]
            if word_id != self.end_idx
        ]

        final_caption = " ".join(words).strip()
        print(f"🎯 Generated caption: '{final_caption}'")
        return final_caption

    def process_video(self, video_url, mood="neutral"):
        """Complete video processing pipeline"""
        try:
            print(f"🎬 Processing video: {video_url}")

            # Download video if it's a URL
            local_video_path = self._download_video_if_needed(video_url)

            # Extract features
            features = self.extract_video_features(local_video_path)

            # Generate caption
            print(f"🤖 Generating caption with mood: {mood}")
            caption = self.generate_caption(features)
            print(f"🔍 Generated base caption: '{caption}'")

            # Apply mood modification
            if mood and mood != "neutral":
                print(f"🎭 Applying mood '{mood}' to caption: '{caption}'")
                caption = self._apply_mood_to_caption(caption, mood)
                print(f"🎯 Final caption after mood: '{caption}'")

            # Cleanup downloaded file if needed
            self._cleanup_temp_file(local_video_path, video_url)

            return caption

        except Exception as e:
            print(f"❌ Error processing video: {str(e)}")
            raise

    def _download_video_if_needed(self, video_url):
        """Download video from URL if needed, return local path"""
        import requests
        import tempfile
        import os
        from urllib.parse import urlparse

        # If it's already a local file, return as-is
        if not video_url.startswith(("http://", "https://")):
            return video_url

        print(f"📥 Downloading video from URL...")

        try:
            # Create temp file
            parsed_url = urlparse(video_url)
            file_ext = os.path.splitext(parsed_url.path)[1] or ".mp4"
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=file_ext)

            # Download with stream
            response = requests.get(video_url, stream=True, timeout=30)
            response.raise_for_status()

            # Write to temp file
            for chunk in response.iter_content(chunk_size=8192):
                temp_file.write(chunk)

            temp_file.close()
            print(f"✅ Video downloaded to: {temp_file.name}")
            return temp_file.name

        except Exception as e:
            print(f"❌ Failed to download video: {e}")
            raise FileNotFoundError(f"Could not download video from {video_url}: {e}")

    def _cleanup_temp_file(self, local_path, original_url):
        """Clean up temporary downloaded file"""
        import os

        # Only delete if it was downloaded (not original local file)
        if original_url.startswith(("http://", "https://")) and os.path.exists(
            local_path
        ):
            try:
                os.unlink(local_path)
                print(f"🗑️ Cleaned up temp file: {local_path}")
            except Exception as e:
                print(f"⚠️ Could not clean up temp file: {e}")

    def _apply_mood_to_caption(self, caption, mood):
        """Apply mood context to caption using Gemini API or fallback"""
        try:
            # Try Gemini first (if available)
            from gemini_integration import refine_caption_with_gemini

            refined = refine_caption_with_gemini(caption, mood)
            if refined and refined != caption:
                return refined
        except ImportError:
            print("⚠️ Gemini integration not available")
        except Exception as e:
            print(f"⚠️ Gemini refinement failed: {e}")

        # Fallback to simple mood modification
        from gemini_integration import apply_simple_mood_modification

        return apply_simple_mood_modification(caption, mood)


# Global instance (singleton pattern)
caption_generator = VideoCaptionGenerator()

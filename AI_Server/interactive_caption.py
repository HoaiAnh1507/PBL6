"""
Interactive Video Captioning - Nhập path liên tục
Nhấn Ctrl+C (CMD+C) để thoát
"""

import os, json, numpy as np, tensorflow as tf
from tensorflow.keras.preprocessing.text import tokenizer_from_json
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow.keras import layers, models
import torch, cv2
from PIL import Image
import open_clip
import time
import sys

# ============== OPTIMIZATION: Disable TensorFlow logs ==============
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"
tf.config.optimizer.set_jit(True)


# Rebuild model architecture
def build_model(feat_dim=768, vocab_size=10364, max_len=47):
    """Rebuild the exact model architecture"""
    vi = layers.Input(shape=(feat_dim,), name="visual")
    vb = layers.Dense(256, activation="relu")(vi)
    vb = layers.Dropout(0.5)(vb)

    si = layers.Input(shape=(max_len,), name="seq_in")
    emb = layers.Embedding(input_dim=vocab_size, output_dim=256, mask_zero=True)(si)
    lstm = layers.LSTM(256)(emb)

    fusion = layers.Add()([vb, lstm])
    hd = layers.Dense(256, activation="relu")(fusion)
    out = layers.Dense(vocab_size)(hd)

    model = models.Model(inputs=[vi, si], outputs=out)
    return model


print("=" * 70)
print("🎬 INTERACTIVE VIDEO CAPTIONING")
print("=" * 70)

# ============== INITIALIZATION (Chỉ chạy 1 lần) ==============
print("\n⏳ Initializing models (this may take a moment)...\n")
init_start = time.time()

# Build and load TensorFlow model
print("  [1/4] Loading TensorFlow model...")
model = build_model(feat_dim=768, vocab_size=10364, max_len=47)
model.load_weights("/Users/duy/Downloads/PBL6/AI_Server/best.weights.h5")
model.compile(optimizer="adam", loss="sparse_categorical_crossentropy")

# Load tokenizer
print("  [2/4] Loading tokenizer...")
with open("/Users/duy/Downloads/PBL6/AI_Server/tokenizer.json", "r") as f:
    tokenizer = tokenizer_from_json(f.read())

# Constants
SPECIAL = {"start": "startseq", "end": "endseq"}
start_idx = tokenizer.word_index[SPECIAL["start"]]
end_idx = tokenizer.word_index[SPECIAL["end"]]
max_len = 47
vocab_size = 10364

# Pre-build idx2word
idx2word = {i: w for w, i in tokenizer.word_index.items()}
idx2word[0] = "<pad>"

# Load CLIP model
print("  [3/4] Loading CLIP model...")
if torch.cuda.is_available():
    device = "cuda"
    device_name = f"CUDA GPU: {torch.cuda.get_device_name(0)}"
elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
    device = "mps"
    device_name = "Apple Silicon GPU (MPS)"
else:
    device = "cpu"
    device_name = "CPU"

clip_model, preprocess, _ = open_clip.create_model_and_transforms(
    "ViT-L-14-336", pretrained="openai", force_quick_gelu=True
)
clip_model = clip_model.to(device).eval()

print(f"  [4/4] Device: {device_name}")

init_time = time.time() - init_start
print(f"\n✅ Initialization complete! ({init_time:.2f}s)")
print("=" * 70)


def generate_caption(video_feature, beam_size=5):
    """Generate caption using optimized beam search"""
    beams = [([start_idx], 0.0)]

    for step in range(max_len - 1):
        candidates = []

        for seq, score in beams:
            if seq[-1] == end_idx:
                candidates.append((seq, score, None))
            else:
                candidates.append((seq, score, seq))

        active_seqs = [c[2] for c in candidates if c[2] is not None]

        if not active_seqs:
            break

        # Batch prediction
        batch_in_seqs = np.array(
            [
                pad_sequences([seq], maxlen=max_len, padding="post")[0]
                for seq in active_seqs
            ]
        )
        batch_video_feats = np.repeat(
            video_feature[np.newaxis, :], len(active_seqs), axis=0
        )

        logits_batch = model.predict(
            [batch_video_feats, batch_in_seqs], verbose=0, batch_size=len(active_seqs)
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

        if all(s[-1] == end_idx for s, _ in beams):
            break

    best_seq = beams[0][0]
    words = [
        idx2word.get(word_id, "") for word_id in best_seq[1:] if word_id != end_idx
    ]

    return " ".join(words).strip()


def extract_video_features(video_path, num_frames=24):
    """Extract 768-dim feature vector from video"""
    cap = cv2.VideoCapture(video_path)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    if total_frames == 0:
        cap.release()
        raise ValueError(f"Cannot read video: {video_path}")

    indices = np.linspace(0, max(total_frames - 1, 0), num=num_frames, dtype=int)

    frames = []
    for idx in indices:
        cap.set(cv2.CAP_PROP_POS_FRAMES, int(idx))
        ret, frame = cap.read()
        if ret:
            frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            frames.append(frame)
    cap.release()

    if not frames:
        raise ValueError(f"No frames extracted from: {video_path}")

    # Batch preprocessing
    preprocessed_frames = []
    for f in frames:
        preprocessed_frames.append(preprocess(Image.fromarray(f)))

    batch = torch.stack(preprocessed_frames).to(device)

    with torch.no_grad(), torch.inference_mode():
        feats = clip_model.encode_image(batch)
        feats = feats / feats.norm(dim=-1, keepdim=True)

    video_feature = feats.mean(dim=0).cpu().numpy()
    return video_feature


def process_video(video_path):
    """Process a single video and return caption with timing"""
    start_time = time.time()

    # Extract features
    print("  ⏳ Extracting features...")
    extract_start = time.time()
    features = extract_video_features(video_path)
    extract_time = time.time() - extract_start

    # Generate caption
    print("  ⏳ Generating caption...")
    caption_start = time.time()
    caption = generate_caption(features, beam_size=5)
    caption_time = time.time() - caption_start

    total_time = time.time() - start_time

    return caption, extract_time, caption_time, total_time


# ============== MAIN INTERACTIVE LOOP ==============
print("\n📝 Ready to process videos!")
print("💡 Tips:")
print("   - Enter video path (absolute or relative)")
print("   - Press Enter to process")
print("   - Press Ctrl+C (CMD+C) to quit")
print("=" * 70)

video_count = 0

try:
    while True:
        print()
        # Get input from user
        try:
            video_path = input("🎬 Enter video path: ").strip()
        except EOFError:
            # Handle Ctrl+D
            print("\n👋 Goodbye!")
            break

        if not video_path:
            print("⚠️  Empty path, please try again.")
            continue

        # Remove quotes if user pasted path with quotes
        video_path = video_path.strip('"').strip("'")

        # Check if file exists
        if not os.path.exists(video_path):
            print(f"❌ Error: File not found - {video_path}")
            continue

        # Check if it's a file
        if not os.path.isfile(video_path):
            print(f"❌ Error: Not a file - {video_path}")
            continue

        # Process video
        print(f"\n{'─'*70}")
        print(f"📹 Processing: {os.path.basename(video_path)}")
        print(f"{'─'*70}")

        try:
            caption, extract_time, caption_time, total_time = process_video(video_path)

            video_count += 1

            # Display results
            print(f"\n✅ SUCCESS!")
            print(f"{'─'*70}")
            print(f"💬 Caption: {caption}")
            print(f"{'─'*70}")
            print(f"⏱️  Timing:")
            print(f"   • Feature extraction: {extract_time:.2f}s")
            print(f"   • Caption generation: {caption_time:.2f}s")
            print(f"   • Total processing:   {total_time:.2f}s")
            print(f"{'─'*70}")
            print(f"📊 Videos processed so far: {video_count}")

        except Exception as e:
            print(f"\n❌ Error processing video: {e}")
            print(f"{'─'*70}")

except KeyboardInterrupt:
    print("\n\n{'='*70}")
    print("🛑 Program stopped by user (Ctrl+C)")
    print(f"📊 Total videos processed: {video_count}")
    print("👋 Goodbye!")
    print("=" * 70)
    sys.exit(0)

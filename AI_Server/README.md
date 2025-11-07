# 🎬 LocketAI Video Caption AI Server

Azure Service Bus Queue-based video captioning service using TensorFlow and CLIP models.

## 📋 Features

- **Video Feature Extraction**: Uses OpenAI CLIP ViT-L-14-336 for visual understanding
- **Caption Generation**: Custom trained TensorFlow model with beam search
- **Mood-based Refinement**: Optional Google Gemini integration for mood context
- **Azure Queue Integration**: Scalable async processing via Service Bus
- **Error Handling**: Robust error handling with dead letter queue support

## 🚀 Quick Start

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Setup Environment

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
# Edit .env with your Azure Service Bus connection string
```

### 3. Verify Model Files

Ensure these files are in the AI_Server directory:

- `best.weights.h5` - Trained model weights
- `tokenizer.json` - Text tokenizer

### 4. Run Queue Worker

```bash
python run_worker.py
```

## 📁 File Structure

```
AI_Server/
├── config.py                 # Configuration management
├── caption_models.py          # Core AI models (TensorFlow + CLIP)
├── queue_worker.py           # Azure Service Bus consumer
├── gemini_integration.py     # Mood-based caption refinement
├── run_worker.py            # Entry point script
├── requirements.txt         # Python dependencies
├── best.weights.h5         # Model weights (required)
├── tokenizer.json          # Text tokenizer (required)
└── .env.example           # Environment template
```

## 🔧 Configuration

### Required Environment Variables

- `AZURE_SERVICEBUS_CONNECTION_STRING`: Azure Service Bus connection string
- `AZURE_QUEUE_NAME`: Queue name (default: "caption-jobs")
- `BACKEND_CALLBACK_SECRET`: Secret for backend authentication

### Optional Configuration

- `GEMINI_API_KEY`: Google Gemini API key for advanced mood refinement
- `MAX_PROCESSING_TIME`: Maximum seconds per video (default: 15)
- `BEAM_SIZE`: Beam search size for caption generation (default: 5)
- `DEVICE`: Processing device (auto/cuda/mps/cpu)

## 🔄 Processing Workflow

1. **Receive Job**: Dequeue message from Azure Service Bus
2. **Extract Features**: Process video frames through CLIP model
3. **Generate Caption**: Use TensorFlow model with beam search
4. **Apply Mood**: Refine caption based on user mood (Gemini or fallback)
5. **Send Result**: HTTP callback to backend with success/failure

### Message Format

Expected queue message structure:

```json
{
  "job_id": "uuid-string",
  "post_id": "123",
  "video_url": "path/to/video.mp4",
  "mood": "happy",
  "callback_url": "http://backend:8080/api/ai/callback/captions"
}
```

### Callback Format

Response sent to backend:

```json
{
  "job_id": "uuid-string",
  "post_id": "123",
  "success": true,
  "caption": "Generated caption text",
  "error_message": null,
  "secret": "authentication-secret"
}
```

## 🎯 Supported Moods

- `happy` - Joyful and upbeat tone
- `sad` - Melancholic and gentle tone
- `excited` - Energetic and enthusiastic
- `grateful` - Appreciative and thankful
- `nostalgic` - Wistful and reminiscent
- `romantic` - Loving and intimate
- `calm` - Peaceful and serene
- `neutral` - No mood modification

## 🛠️ Development

### Testing Individual Components

```bash
# Test caption generation
python -c "from caption_models import caption_generator; caption_generator.initialize(); print(caption_generator.process_video('test_video.mp4', 'happy'))"

# Test Gemini integration
python gemini_integration.py

# Test queue worker (dry run)
python queue_worker.py
```

### Performance Optimization

- **Model Loading**: Models are loaded once at startup
- **Device Detection**: Automatic GPU/CPU selection
- **Batch Processing**: Efficient frame sampling from videos
- **Memory Management**: Proper cleanup of video resources

## 🔒 Security

- **Authentication**: Backend callbacks require secret validation
- **Error Isolation**: Failed jobs moved to dead letter queue
- **Timeout Protection**: Max processing time prevents hanging
- **Resource Cleanup**: Proper disposal of video and tensor resources

## 📊 Monitoring

Worker logs include:

- Job processing times
- Success/failure rates
- Model initialization status
- Queue connection health
- Device utilization info

## 🐛 Troubleshooting

### Common Issues

**"Failed to connect to Azure Service Bus"**

- Check connection string format
- Verify network connectivity
- Ensure queue exists

**"Model files not found"**

- Verify `best.weights.h5` and `tokenizer.json` exist
- Check file permissions

**"CUDA out of memory"**

- Reduce batch size or use CPU
- Set `DEVICE=cpu` in environment

**"Video processing timeout"**

- Increase `MAX_PROCESSING_TIME`
- Check video file accessibility
- Verify video format support

### Debug Mode

Enable verbose logging:

```bash
export TF_CPP_MIN_LOG_LEVEL=0
python run_worker.py
```

## 📈 Scaling

For production deployment:

- Run multiple worker instances
- Use container orchestration (Docker/Kubernetes)
- Monitor queue depth and processing times
- Scale based on queue backlog

## 🤝 Integration

This AI Server integrates with:

- **Backend**: Spring Boot application via HTTP callbacks
- **Queue**: Azure Service Bus for job distribution
- **Storage**: Video files from mobile uploads
- **Gemini**: Optional Google AI for caption refinement

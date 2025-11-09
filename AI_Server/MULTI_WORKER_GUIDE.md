# 🚀 Multi-Worker Configuration Guide

## 📊 Tổng quan

Multi-worker system cho phép xử lý **nhiều video captions đồng thời**, tăng throughput đáng kể khi có nhiều requests cùng lúc.

---

## ⚙️ Configuration

### 1. Environment Variables (.env file)

```bash
# Azure Service Bus
AZURE_SERVICEBUS_CONNECTION_STRING=Endpoint=sb://...
AZURE_QUEUE_NAME=caption-jobs

# Multi-Worker Settings
NUM_WORKERS=2          # Số workers chạy đồng thời (default: 1)
PREFETCH_COUNT=1       # Số messages mỗi worker prefetch (default: 1)

# Processing Settings
MAX_PROCESSING_TIME=15
BEAM_SIZE=5
```

### 2. Worker Count Guidelines

| Số Workers | RAM Needed | Use Case                                         |
| ---------- | ---------- | ------------------------------------------------ |
| **1**      | ~4GB       | Testing, low traffic                             |
| **2-3**    | ~8-12GB    | Production (recommended) ⭐                      |
| **4-6**    | ~16-24GB   | High traffic                                     |
| **>6**     | ~32GB+     | Very high traffic (cẩn thận resource contention) |

**Lưu ý**:

- Mỗi worker cần ~4GB RAM (model + CLIP)
- CPU: Ít nhất 2 cores per worker
- GPU: Nếu có multiple GPUs, workers sẽ auto-distribute

---

## 🚀 Usage

### Option 1: Single Worker (Đơn giản)

```bash
cd AI_Server
python run_worker.py
```

### Option 2: Multi-Worker (Recommended)

```bash
cd AI_Server

# Sử dụng config mặc định (NUM_WORKERS từ .env)
python multi_worker.py

# Hoặc chỉ định số workers
python multi_worker.py --workers 3

# Hoặc dùng script
./start_multi_worker.sh 3
```

---

## 📈 Performance Comparison

### Single Worker

```
Job 1: 0s  ━━━━━━━━━━━━━━━━ 17s
Job 2:                      17s ━━━━━━━━━━━━━━━━ 34s
Job 3:                                        34s ━━━━━━━━━━━━━━━━ 51s
Total: 51 seconds
```

### 3 Workers

```
Job 1: 0s  ━━━━━━━━━━━━━━━━ 17s
Job 2: 0s  ━━━━━━━━━━━━━━━━ 17s
Job 3: 0s  ━━━━━━━━━━━━━━━━ 17s
Total: 17 seconds (3x faster!)
```

---

## 🔧 Advanced Settings

### Prefetch Count

Control số messages mỗi worker fetch trước:

```bash
PREFETCH_COUNT=1   # Conservative (default) - 1 message tại 1 thời điểm
PREFETCH_COUNT=2   # Moderate - worker fetch 2 messages
PREFETCH_COUNT=5   # Aggressive - worker có buffer 5 messages
```

**Trade-offs**:

- **Higher prefetch**: Lower latency, better throughput
- **Lower prefetch**: More fair distribution, less memory

**Recommended**:

- CPU-only: `PREFETCH_COUNT=1`
- GPU available: `PREFETCH_COUNT=2-3`

---

## 🎯 Architecture

```
Azure Service Bus Queue
    │
    ├─── Worker 1 (PID: 1234) ──► AI Model ──► Process Video 1
    │
    ├─── Worker 2 (PID: 1235) ──► AI Model ──► Process Video 2
    │
    └─── Worker 3 (PID: 1236) ──► AI Model ──► Process Video 3
```

**Key Features**:

- **Process Isolation**: Each worker runs in separate process
- **Independent Models**: Each worker loads its own TensorFlow/CLIP models
- **Auto Restart**: Manager restarts crashed workers automatically
- **Graceful Shutdown**: Ctrl+C stops all workers cleanly

---

## 📊 Monitoring

### Logs

Each worker prefixes logs with ID:

```
[Worker 1] 🚀 Initializing Queue Worker...
[Worker 2] 🚀 Initializing Queue Worker...
[Worker 1] 📥 Processing job | ID: abc123... | Post: 42 | Mood: happy
[Worker 2] 📥 Processing job | ID: def456... | Post: 43 | Mood: sad
[Worker 1] ✅ Caption generated in 16.5s: a cat is eating
[Worker 2] ✅ Caption generated in 15.2s: a person is walking
```

### Health Check

The manager monitors workers and auto-restarts if crashed:

```
⚠️  Worker 2 died (exit code: 1)
🔄 Restarting worker 2...
✅ Worker 2 restarted (PID: 1240)
```

---

## 🛠️ Troubleshooting

### Issue: Workers compete for GPU

**Solution**: Set GPU device per worker

```python
# In multi_worker.py, modify _worker_process:
os.environ['CUDA_VISIBLE_DEVICES'] = str(worker_id % num_gpus)
```

### Issue: Out of Memory

**Symptoms**: Workers crash with OOM errors

**Solution**:

1. Reduce `NUM_WORKERS`
2. Enable GPU memory growth (already in code)
3. Add swap space

### Issue: Workers slow to start

**Expected**: Each worker takes ~30s to load models

**Normal behavior**: Stagger startup (0.5s delay per worker)

### Issue: Uneven load distribution

**Solution**: Increase `PREFETCH_COUNT` to 2-3

---

## 🔬 Testing

### Test Single Worker

```bash
# Terminal 1: Start worker
python run_worker.py

# Terminal 2: Send test job
curl -X POST http://localhost:8080/api/posts/ai/init \
  -H "Content-Type: application/json" \
  -d '{
    "mediaType": "VIDEO",
    "mediaUrl": "https://example.com/video.mp4",
    "mood": "happy"
  }'
```

### Test Multi-Worker

```bash
# Terminal 1: Start 3 workers
python multi_worker.py --workers 3

# Terminal 2: Send multiple jobs rapidly
for i in {1..10}; do
  curl -X POST http://localhost:8080/api/posts/ai/init \
    -H "Content-Type: application/json" \
    -d "{\"mediaType\":\"VIDEO\",\"mediaUrl\":\"https://example.com/video$i.mp4\",\"mood\":\"happy\"}" &
done
```

Watch logs - you should see all 3 workers processing simultaneously!

---

## 💡 Best Practices

1. **Start with 2-3 workers** for production
2. **Monitor memory usage** - don't overcommit
3. **Use prefetch** only if you have spare memory
4. **Keep workers < CPU cores** to avoid thrashing
5. **Test under load** before going to production

---

## 🚦 Production Deployment

### Systemd Service (Linux)

Create `/etc/systemd/system/locketai-workers.service`:

```ini
[Unit]
Description=LocketAI Multi-Worker Caption Service
After=network.target

[Service]
Type=simple
User=locketai
WorkingDirectory=/opt/locketai/AI_Server
Environment="NUM_WORKERS=3"
ExecStart=/opt/locketai/AI_Server/ai_caption_env/bin/python multi_worker.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable locketai-workers
sudo systemctl start locketai-workers
sudo systemctl status locketai-workers
```

### Docker Compose

```yaml
version: "3.8"
services:
  caption-workers:
    build: ./AI_Server
    environment:
      - NUM_WORKERS=3
      - PREFETCH_COUNT=2
      - AZURE_SERVICEBUS_CONNECTION_STRING=${AZURE_CONN}
    deploy:
      resources:
        limits:
          memory: 12G
    restart: always
```

---

## 📞 Support

**Issues**: Check logs with worker ID prefix  
**Performance**: Tune `NUM_WORKERS` and `PREFETCH_COUNT`  
**Debugging**: Run single worker first: `python run_worker.py`

---

**Status**: ✅ Ready for Production  
**Version**: 2.0 (Multi-Worker)  
**Last Updated**: November 9, 2025

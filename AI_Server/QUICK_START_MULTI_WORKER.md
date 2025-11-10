# 🚀 Quick Start: Multi-Worker System

## ✅ System Status: WORKING!

Multi-worker system đã được fix và test thành công!

---

## 📝 Cách Chạy

### 1. Single Worker (như cũ)

```bash
cd AI_Server
python run_worker.py
```

### 2. Multi-Worker (MỚI - RECOMMENDED)

```bash
cd AI_Server

# Option 1: Dùng script
./start_multi_worker.sh 2     # 2 workers

# Option 2: Trực tiếp với Python venv
./ai_caption_env/bin/python3 multi_worker.py --workers 2

# Option 3: Với số workers khác
./ai_caption_env/bin/python3 multi_worker.py --workers 3
```

---

## ⚙️ Configuration (.env)

```bash
# Multi-Worker Settings
NUM_WORKERS=2          # Default number of workers
PREFETCH_COUNT=1       # Messages per worker

# Azure
AZURE_SERVICEBUS_CONNECTION_STRING=...
AZURE_QUEUE_NAME=caption_jobs
```

---

## 📊 Resource Requirements

| Workers | RAM     | Use Case          |
| ------- | ------- | ----------------- |
| 1       | 4GB     | Testing           |
| 2-3     | 8-12GB  | **Production** ⭐ |
| 4-6     | 16-24GB | High traffic      |

---

## 🎯 Expected Output

```
================================================================================
🚀 LocketAI Multi-Worker Manager
   Workers: 2
================================================================================
✅ Started worker 1 (PID: 1874)
✅ Started worker 2 (PID: 1875)

[Worker 1] 🚀 Initializing Queue Worker...
[Worker 2] 🚀 Initializing Queue Worker...

✅ Models initialized! (9.54s)

[Worker 1] ✅ Connected to queue: caption_jobs
[Worker 2] ✅ Connected to queue: caption_jobs
[Worker 1] 🔄 Starting queue worker loop...
[Worker 2] 🔄 Starting queue worker loop...

👀 Monitoring 2 workers...
```

---

## 🐛 Troubleshooting

### Issue: "cannot pickle" error

✅ **FIXED!** - Sử dụng standalone function cho worker process

### Issue: Wrong Python version

**Solution**: Dùng venv Python:

```bash
./ai_caption_env/bin/python3 multi_worker.py --workers 2
```

### Issue: Workers slow to start

**Normal**: Mỗi worker load models ~10s

---

## 📈 Performance

### Before (1 worker):

```
6 videos = 6 × 17s = 102 seconds
```

### After (3 workers):

```
6 videos = 2 batches × 17s = 34 seconds (3x faster!)
```

---

## 🎓 Next Steps

1. ✅ **Test với real videos** - Submit nhiều jobs
2. ✅ **Monitor RAM usage** - Adjust NUM_WORKERS nếu cần
3. ✅ **Production deployment** - Sử dụng 2-3 workers

---

**Status**: ✅ WORKING  
**Version**: 2.0 (Multi-Worker)  
**Last Updated**: November 9, 2025

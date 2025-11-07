"""
Configuration for AI Server Azure Service Bus integration
"""

import os
from pathlib import Path

# Load .env file if exists
try:
    from dotenv import load_dotenv

    env_path = Path(".") / ".env"
    if env_path.exists():
        load_dotenv(env_path)
        print("📄 Loaded .env file")
except ImportError:
    print("⚠️ python-dotenv not installed, using environment variables only")

# Azure Service Bus Configuration
AZURE_SERVICEBUS_CONNECTION_STRING = os.getenv(
    "AZURE_SERVICEBUS_CONNECTION_STRING",
    "Endpoint=sb://your-servicebus.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=YOUR_ACCESS_KEY_HERE",
)

AZURE_QUEUE_NAME = os.getenv("AZURE_QUEUE_NAME", "caption-jobs")

# Backend Callback Configuration
BACKEND_CALLBACK_SECRET = os.getenv("BACKEND_CALLBACK_SECRET", "change-me")

# Processing Configuration
MAX_PROCESSING_TIME = int(os.getenv("MAX_PROCESSING_TIME", "15"))  # seconds
BEAM_SIZE = int(os.getenv("BEAM_SIZE", "5"))

# Model Paths
MODEL_WEIGHTS_PATH = "best.weights.h5"
TOKENIZER_PATH = "tokenizer.json"

# Device Configuration (auto-detect)
DEVICE_PREFERENCE = os.getenv("DEVICE", "auto")  # auto, cuda, mps, cpu

print(f"🔧 Config loaded:")
print(f"   Queue: {AZURE_QUEUE_NAME}")
print(f"   Max processing time: {MAX_PROCESSING_TIME}s")
print(f"   Beam size: {BEAM_SIZE}")

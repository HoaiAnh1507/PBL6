#!/bin/bash
# Start AI Server Queue Worker with clean environment

cd "$(dirname "$0")"

# Unset any system environment variables that might conflict
unset GEMINI_API_KEY
unset AZURE_SERVICEBUS_CONNECTION_STRING
unset AZURE_QUEUE_NAME

# Run the worker
./ai_caption_env/bin/python3 run_worker.py

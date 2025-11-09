#!/bin/bash
# LocketAI Multi-Worker Launcher
# Usage: ./start_multi_worker.sh [num_workers]

# Default to 2 workers if not specified
NUM_WORKERS=${1:-2}

echo "🚀 Starting LocketAI Multi-Worker System"
echo "   Workers: $NUM_WORKERS"
echo ""

# Activate virtual environment if exists
if [ -d "ai_caption_env" ]; then
    echo "📦 Activating virtual environment..."
    source ai_caption_env/bin/activate
fi

# Run multi-worker manager
echo "▶️  Launching workers..."
python3 multi_worker.py --workers $NUM_WORKERS

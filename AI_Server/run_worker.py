#!/usr/bin/env python3
"""
LocketAI Video Caption Queue Worker
Entry point script for running the Azure Service Bus consumer
"""

import os
import sys

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def check_dependencies():
    """Check if all required dependencies are installed"""
    required_packages = [
        "azure.servicebus",
        "requests",
        "tensorflow",
        "torch",
        "cv2",
        "PIL",
        "open_clip",
        "numpy",
    ]

    missing = []
    for package in required_packages:
        try:
            if package == "cv2":
                import cv2
            elif package == "PIL":
                from PIL import Image
            elif package == "open_clip":
                import open_clip
            else:
                __import__(package)
        except ImportError:
            missing.append(package)

    if missing:
        print("❌ Missing required packages:")
        for pkg in missing:
            print(f"   - {pkg}")
        print("\n💡 Install missing packages with:")
        print("   pip install -r requirements.txt")
        sys.exit(1)

    print("✅ All dependencies are installed")


def check_model_files():
    """Check if required model files exist"""
    required_files = ["best.weights.h5", "tokenizer.json"]

    missing = []
    for file in required_files:
        if not os.path.exists(file):
            missing.append(file)

    if missing:
        print("❌ Missing required model files:")
        for file in missing:
            print(f"   - {file}")
        print("\n💡 Make sure the following files are in the AI_Server directory:")
        print("   - best.weights.h5 (trained model weights)")
        print("   - tokenizer.json (text tokenizer)")
        sys.exit(1)

    print("✅ All model files found")


def main():
    """Main entry point"""
    print("🎬 LocketAI Caption Queue Worker")
    print("=" * 70)

    # Check environment
    print("🔍 Checking environment...")
    check_dependencies()
    check_model_files()

    # Import and run worker
    try:
        from queue_worker import main as worker_main

        worker_main()
    except KeyboardInterrupt:
        print("\n⏹️ Worker stopped by user")
    except Exception as e:
        print(f"💥 Worker failed: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()

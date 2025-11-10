#!/usr/bin/env python3
"""
Multi-Worker Manager for LocketAI Video Caption Queue
Spawns and manages multiple worker processes for concurrent job processing
"""

import os
import sys
import time
import signal
import multiprocessing as mp
from typing import List

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config import NUM_WORKERS


def _worker_process_func(worker_id: int):
    """Worker process entry point (standalone function to avoid pickling issues)"""
    # Import here to avoid issues with multiprocessing
    from queue_worker import QueueWorker

    print(f"👷 Worker {worker_id} starting...")

    try:
        worker = QueueWorker(worker_id=worker_id)
        worker.initialize()
        worker.run()
    except KeyboardInterrupt:
        print(f"👷 Worker {worker_id} interrupted")
    except Exception as e:
        print(f"❌ Worker {worker_id} crashed: {e}")
        import traceback

        traceback.print_exc()
    finally:
        print(f"👷 Worker {worker_id} stopped")


class WorkerManager:
    def __init__(self, num_workers: int = None):
        self.num_workers = num_workers or NUM_WORKERS
        self.worker_processes: List[mp.Process] = []
        self.running = True

        # Note: Signal handlers set up in run() to avoid pickling issues

    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        print(f"\n🛑 Received signal {signum}, shutting down all workers...")
        self.running = False
        self.stop_all_workers()

    def start_workers(self):
        """Spawn all worker processes"""
        print("=" * 80)
        print(f"🚀 LocketAI Multi-Worker Manager")
        print(f"   Workers: {self.num_workers}")
        print("=" * 80)

        # Check if multi-GPU available for distribution
        self._check_gpu_availability()

        # Spawn workers using standalone function
        for i in range(self.num_workers):
            worker_id = i + 1
            process = mp.Process(
                target=_worker_process_func,  # ← Use standalone function!
                args=(worker_id,),
                name=f"Worker-{worker_id}",
            )
            process.start()
            self.worker_processes.append(process)
            print(f"✅ Started worker {worker_id} (PID: {process.pid})")
            time.sleep(0.5)  # Stagger startup to avoid resource conflicts

        print(f"\n✅ All {self.num_workers} workers started!")
        print("=" * 80)

    def _check_gpu_availability(self):
        """Check and report GPU availability"""
        try:
            import torch

            if torch.cuda.is_available():
                gpu_count = torch.cuda.device_count()
                print(f"🎮 GPU available: {gpu_count} CUDA device(s)")
                if gpu_count >= self.num_workers:
                    print(f"   ✅ Can assign 1 GPU per worker")
                else:
                    print(
                        f"   ⚠️  Workers will share GPUs ({self.num_workers} workers, {gpu_count} GPUs)"
                    )
            elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
                print(f"🍎 Apple Silicon GPU (MPS) available")
                print(f"   ⚠️  MPS doesn't support multi-process, workers will share")
            else:
                print(f"💻 CPU only mode")
        except Exception as e:
            print(f"⚠️  Could not check GPU: {e}")

    def monitor_workers(self):
        """Monitor worker processes and restart if crashed"""
        print(f"\n👀 Monitoring {self.num_workers} workers...")
        print("   Press Ctrl+C to stop all workers")
        print("-" * 80)

        check_interval = 5  # seconds

        try:
            while self.running:
                time.sleep(check_interval)

                # Check each worker
                for i, process in enumerate(self.worker_processes):
                    worker_id = i + 1

                    if not process.is_alive():
                        exit_code = process.exitcode
                        print(f"\n⚠️  Worker {worker_id} died (exit code: {exit_code})")

                        if self.running and exit_code != 0:
                            # Restart crashed worker
                            print(f"🔄 Restarting worker {worker_id}...")
                            new_process = mp.Process(
                                target=_worker_process_func,  # ← Use standalone function!
                                args=(worker_id,),
                                name=f"Worker-{worker_id}",
                            )
                            new_process.start()
                            self.worker_processes[i] = new_process
                            print(
                                f"✅ Worker {worker_id} restarted (PID: {new_process.pid})"
                            )

        except KeyboardInterrupt:
            print("\n🛑 Monitoring interrupted")

    def stop_all_workers(self):
        """Stop all worker processes gracefully"""
        print(f"\n🛑 Stopping {len(self.worker_processes)} workers...")

        # Send SIGTERM to all workers
        for i, process in enumerate(self.worker_processes):
            if process.is_alive():
                worker_id = i + 1
                print(f"   Stopping worker {worker_id}...")
                process.terminate()

        # Wait for graceful shutdown
        shutdown_timeout = 10
        start_time = time.time()

        while time.time() - start_time < shutdown_timeout:
            all_stopped = all(not p.is_alive() for p in self.worker_processes)
            if all_stopped:
                break
            time.sleep(0.5)

        # Force kill if still running
        for i, process in enumerate(self.worker_processes):
            if process.is_alive():
                worker_id = i + 1
                print(f"   Force killing worker {worker_id}...")
                process.kill()

        # Join all processes
        for process in self.worker_processes:
            process.join()

        print("✅ All workers stopped")

    def run(self):
        """Main entry point"""
        # Setup signal handlers HERE (after object creation, before starting workers)
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)

        try:
            self.start_workers()
            self.monitor_workers()
        except Exception as e:
            print(f"💥 Manager error: {e}")
            import traceback

            traceback.print_exc()
        finally:
            self.stop_all_workers()


def main():
    """Entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="LocketAI Multi-Worker Manager")
    parser.add_argument(
        "--workers",
        type=int,
        default=None,
        help=f"Number of workers (default: NUM_WORKERS from config or 1)",
    )

    args = parser.parse_args()

    # Override config if specified
    num_workers = args.workers or NUM_WORKERS

    if num_workers < 1:
        print("❌ Number of workers must be >= 1")
        sys.exit(1)

    if num_workers > 8:
        print("⚠️  Warning: More than 8 workers may cause resource contention")
        response = input("Continue? (y/n): ")
        if response.lower() != "y":
            sys.exit(0)

    # Start manager
    manager = WorkerManager(num_workers=num_workers)
    manager.run()


if __name__ == "__main__":
    # Required for multiprocessing on macOS/Windows
    mp.set_start_method("spawn", force=True)
    main()

import multiprocessing as mp
import sys
sys.path.insert(0, '.')

def worker_test(worker_id):
    print(f"Worker {worker_id} started!")
    from queue_worker import QueueWorker
    worker = QueueWorker(worker_id=worker_id)
    print(f"Worker {worker_id} created successfully!")

if __name__ == "__main__":
    mp.set_start_method('spawn', force=True)
    p = mp.Process(target=worker_test, args=(1,))
    p.start()
    p.join(timeout=5)
    if p.is_alive():
        p.terminate()
    print("✅ Test completed!")

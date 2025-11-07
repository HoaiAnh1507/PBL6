"""
Azure Service Bus Queue Worker for Video Caption Generation
"""

import json
import time
import signal
import sys
import traceback
import requests
from typing import Dict, Any
from azure.servicebus import ServiceBusClient, ServiceBusReceiver
from azure.servicebus.exceptions import ServiceBusError

from config import (
    AZURE_SERVICEBUS_CONNECTION_STRING,
    AZURE_QUEUE_NAME,
    BACKEND_CALLBACK_SECRET,
    MAX_PROCESSING_TIME,
)
from caption_models import caption_generator


class QueueWorker:
    def __init__(self):
        self.client = None
        self.receiver = None
        self.running = True
        self.processed_count = 0

        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)

    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        print(f"\n🛑 Received signal {signum}, shutting down gracefully...")
        self.running = False

    def initialize(self):
        """Initialize Azure Service Bus client and AI models"""
        print("🚀 Initializing Queue Worker...")

        # Debug connection string (hide sensitive parts)
        masked_conn = (
            AZURE_SERVICEBUS_CONNECTION_STRING[:50] + "..."
            if len(AZURE_SERVICEBUS_CONNECTION_STRING) > 50
            else AZURE_SERVICEBUS_CONNECTION_STRING
        )
        print(f"🔗 Connection: {masked_conn}")
        print(f"📦 Queue Name: {AZURE_QUEUE_NAME}")

        # Initialize AI models first (takes time)
        caption_generator.initialize()

        # Initialize Azure Service Bus
        print("📡 Connecting to Azure Service Bus...")
        try:
            self.client = ServiceBusClient.from_connection_string(
                AZURE_SERVICEBUS_CONNECTION_STRING
            )
            self.receiver = self.client.get_queue_receiver(
                queue_name=AZURE_QUEUE_NAME,
                max_wait_time=5,  # Reduce timeout to avoid AMQP issues
            )
            print(f"✅ Connected to queue: {AZURE_QUEUE_NAME}")
        except Exception as e:
            print(f"❌ Failed to connect to Azure Service Bus: {e}")
            print(
                f"🔍 Connection string length: {len(AZURE_SERVICEBUS_CONNECTION_STRING)}"
            )
            print(f"🔍 Queue name: '{AZURE_QUEUE_NAME}'")
            raise

    def run(self):
        """Main worker loop"""
        print("🔄 Starting queue worker loop...")
        print(f"📊 Max processing time: {MAX_PROCESSING_TIME}s")
        print("=" * 70)

        try:
            while self.running:
                try:
                    # Receive messages from queue with shorter timeout
                    received_msgs = self.receiver.receive_messages(
                        max_message_count=1,
                        max_wait_time=2,  # Shorter wait time to prevent AMQP issues
                    )

                    if not received_msgs:
                        # No messages, short sleep and continue
                        print(".", end="", flush=True)  # Show activity
                        time.sleep(1)
                        continue

                    for message in received_msgs:
                        if not self.running:
                            break

                        try:
                            self._process_message(message)
                            # Complete the message (remove from queue)
                            self.receiver.complete_message(message)
                            self.processed_count += 1

                        except Exception as e:
                            print(f"❌ Error processing message: {e}")
                            print(f"🔍 Traceback: {traceback.format_exc()}")

                            # Dead letter the message (move to DLQ)
                            try:
                                self.receiver.dead_letter_message(
                                    message,
                                    reason="ProcessingError",
                                    error_description=str(e),
                                )
                            except Exception as dlq_error:
                                print(f"⚠️ Failed to dead letter message: {dlq_error}")

                except ServiceBusError as e:
                    print(f"🔌 Service Bus error: {e}")
                    time.sleep(5)  # Wait before retry
                except Exception as e:
                    print(f"💥 Unexpected error: {e}")
                    time.sleep(2)

        finally:
            self._cleanup()

    def _process_message(self, message):
        """Process a single caption job message"""
        try:
            # Parse message body
            job_data = json.loads(str(message))

            job_id = job_data.get("job_id")
            post_id = job_data.get("post_id")
            video_url = job_data.get("video_url")
            mood = job_data.get("mood", "neutral")
            callback_url = job_data.get("callback_url")

            print(
                f"\n📥 Processing job | ID: {job_id} | Post: {post_id} | Mood: {mood}"
            )

            # Validate required fields
            if not all([job_id, post_id, video_url, callback_url]):
                raise ValueError("Missing required fields in message")

            # Process with timeout
            start_time = time.time()

            try:
                # Add timeout for caption generation
                import signal

                def timeout_handler(signum, frame):
                    raise TimeoutError(
                        f"Caption generation timed out after {MAX_PROCESSING_TIME}s"
                    )

                # Set timeout signal
                signal.signal(signal.SIGALRM, timeout_handler)
                signal.alarm(MAX_PROCESSING_TIME)

                try:
                    # Generate caption (this is the main work)
                    caption = caption_generator.process_video(video_url, mood)

                    # Clear timeout
                    signal.alarm(0)

                    processing_time = time.time() - start_time

                    print(
                        f"✅ Caption generated in {processing_time:.1f}s: {caption[:50]}..."
                    )

                    # Send success callback
                    self._send_callback(
                        callback_url=callback_url,
                        job_id=job_id,
                        post_id=post_id,
                        success=True,
                        caption=caption,
                        error_message=None,
                    )

                except TimeoutError as te:
                    signal.alarm(0)  # Clear timeout
                    processing_time = time.time() - start_time
                    error_msg = (
                        f"Caption generation timed out after {MAX_PROCESSING_TIME}s"
                    )

                    print(
                        f"⏰ {error_msg} (processing stopped at {processing_time:.1f}s)"
                    )

                    # Send failure callback
                    self._send_callback(
                        callback_url=callback_url,
                        job_id=job_id,
                        post_id=post_id,
                        success=False,
                        caption=None,
                        error_message=error_msg,
                    )

            except Exception as processing_error:
                processing_time = time.time() - start_time
                error_msg = f"Caption generation failed: {str(processing_error)}"

                print(f"❌ {error_msg} (after {processing_time:.1f}s)")

                # Send failure callback
                self._send_callback(
                    callback_url=callback_url,
                    job_id=job_id,
                    post_id=post_id,
                    success=False,
                    caption=None,
                    error_message=error_msg,
                )

        except Exception as e:
            print(f"💥 Message parsing error: {e}")
            raise

    def _send_callback(
        self,
        callback_url: str,
        job_id: str,
        post_id: str,
        success: bool,
        caption: str = None,
        error_message: str = None,
    ):
        """Send result back to backend via HTTP callback"""

        payload = {
            "jobId": job_id,
            "postId": post_id,
            "success": success,
            "caption": caption,
            "errorMessage": error_message,
            "secret": BACKEND_CALLBACK_SECRET,
        }

        try:
            print(f"📤 Sending callback to: {callback_url}")
            print(f"🔍 Payload: {payload}")

            response = requests.post(
                callback_url,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=10,
            )

            print(f"🔍 Response status: {response.status_code}")
            print(f"🔍 Response headers: {dict(response.headers)}")

            if response.status_code == 200:
                print(f"✅ Callback sent successfully")
            else:
                print(f"⚠️ Callback failed: HTTP {response.status_code}")
                print(f"   Response body: {response.text}")
                # Try to parse error details
                try:
                    error_json = response.json()
                    print(f"   Error details: {error_json}")
                except:
                    pass

        except requests.RequestException as e:
            print(f"❌ Callback request failed: {e}")
            # Don't raise - this shouldn't fail the job processing

    def _cleanup(self):
        """Clean up resources"""
        print(f"\n🧹 Cleaning up... (processed {self.processed_count} jobs)")

        if self.receiver:
            try:
                self.receiver.close()
            except:
                pass

        if self.client:
            try:
                self.client.close()
            except:
                pass

        print("👋 Queue worker stopped")


def main():
    """Main entry point"""
    print("🎬 LocketAI Video Caption Queue Worker")
    print("=" * 70)

    worker = QueueWorker()

    try:
        worker.initialize()
        worker.run()
    except KeyboardInterrupt:
        print("\n⏹️ Interrupted by user")
    except Exception as e:
        print(f"💥 Fatal error: {e}")
        print(f"🔍 Traceback: {traceback.format_exc()}")
        sys.exit(1)


if __name__ == "__main__":
    main()

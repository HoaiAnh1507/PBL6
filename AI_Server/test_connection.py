#!/usr/bin/env python3
"""
Quick test Azure Service Bus connection
"""

import os
from dotenv import load_dotenv
from azure.servicebus import ServiceBusClient

# Load environment
load_dotenv()

connection_string = os.getenv("AZURE_SERVICEBUS_CONNECTION_STRING")
queue_name = os.getenv("AZURE_QUEUE_NAME", "caption-jobs")

print(f"🔗 Testing connection...")
print(f"📦 Queue: {queue_name}")

try:
    client = ServiceBusClient.from_connection_string(connection_string)

    # Try to get queue receiver
    receiver = client.get_queue_receiver(queue_name)
    print(f"✅ Successfully connected to queue: {queue_name}")

    receiver.close()
    client.close()

except Exception as e:
    print(f"❌ Connection failed: {e}")
    print(f"🔍 Error type: {type(e).__name__}")

    # Suggestions based on error
    if "amqp:client-error" in str(e):
        print("💡 Possible fixes:")
        print("   1. Check if queue exists in Azure Portal")
        print("   2. Verify connection string is correct")
        print("   3. Ensure access key has queue permissions")

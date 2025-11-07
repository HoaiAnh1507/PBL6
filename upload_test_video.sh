#!/bin/bash
# Upload test video to Azure Storage
# Requires Azure CLI: az login

STORAGE_ACCOUNT="locketai"
CONTAINER="media"
VIDEO_FILE="test_video.mp4"  # Đường dẫn đến video local

echo "📤 Uploading $VIDEO_FILE to Azure Storage..."

# Upload file
az storage blob upload \
    --account-name $STORAGE_ACCOUNT \
    --container-name $CONTAINER \
    --name "test/$VIDEO_FILE" \
    --file "$VIDEO_FILE" \
    --overwrite

# Get public URL
URL=$(az storage blob url \
    --account-name $STORAGE_ACCOUNT \
    --container-name $CONTAINER \
    --name "test/$VIDEO_FILE" \
    --output tsv)

echo "✅ Video uploaded!"
echo "🔗 Public URL: $URL"
echo ""
echo "📋 Use this URL in Postman:"
echo "\"mediaUrl\": \"$URL\""
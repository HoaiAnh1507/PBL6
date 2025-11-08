package com.pbl6.backend.service;

import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.BlobServiceClientBuilder;
import com.azure.storage.blob.sas.BlobSasPermission;
import com.azure.storage.blob.sas.BlobServiceSasSignatureValues;
import com.azure.storage.common.StorageSharedKeyCredential;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.Map;

@Service
public class StorageService {
    private static final Logger log = LoggerFactory.getLogger(StorageService.class);

    private final String connectionString;

    public StorageService(
            @Value("${azure.storage.connection-string}") String connectionString
    ) {
        this.connectionString = connectionString;
    }

    private BlobServiceClient buildServiceClient() {
        return new BlobServiceClientBuilder()
                .connectionString(connectionString)
                .buildClient();
    }

    /**
     * Generate a read-only SAS token for a specific blob.
     * @param containerName Azure Blob container name
     * @param blobName Blob name (path within container)
     * @param expiresInSeconds Token lifetime in seconds (default suggest: 300)
     * @return Map with keys: sasToken, signedUrl, expiresOn
     */
    public Map<String, Object> generateBlobReadSas(String containerName, String blobName, int expiresInSeconds) {
        if (containerName == null || containerName.isBlank()) {
            throw new IllegalArgumentException("containerName is required");
        }
        if (blobName == null || blobName.isBlank()) {
            throw new IllegalArgumentException("blobName is required");
        }
        if (expiresInSeconds <= 0) {
            expiresInSeconds = 300; // fallback 5 minutes
        }

        BlobServiceClient serviceClient = buildServiceClient();
        BlobContainerClient containerClient = serviceClient.getBlobContainerClient(containerName);
        BlobClient blobClient = containerClient.getBlobClient(blobName);

        OffsetDateTime startsOn = OffsetDateTime.now().minusSeconds(30); // clock skew tolerance
        OffsetDateTime expiresOn = OffsetDateTime.now().plusSeconds(expiresInSeconds);

        BlobSasPermission permissions = new BlobSasPermission().setReadPermission(true);
        BlobServiceSasSignatureValues signatureValues = new BlobServiceSasSignatureValues(expiresOn, permissions)
                .setStartTime(startsOn);

        String sasToken = blobClient.generateSas(signatureValues);
        String signedUrl = blobClient.getBlobUrl() + "?" + sasToken;

        Map<String, Object> result = new HashMap<>();
        result.put("sasToken", sasToken);
        result.put("signedUrl", signedUrl);
        result.put("expiresOn", expiresOn.toString());

        log.debug("Generated SAS for container={}, blob={}, expiresOn={}", containerName, blobName, expiresOn);
        return result;
    }

    /**
     * Generate an upload SAS token (create + write [+ read]) for a specific blob.
     * Use when client needs to upload a new blob or overwrite existing.
     */
    public Map<String, Object> generateBlobUploadSas(String containerName, String blobName, int expiresInSeconds) {
        if (containerName == null || containerName.isBlank()) {
            throw new IllegalArgumentException("containerName is required");
        }
        if (blobName == null || blobName.isBlank()) {
            throw new IllegalArgumentException("blobName is required");
        }
        if (expiresInSeconds <= 0) {
            expiresInSeconds = 300; // fallback 5 minutes
        }

        BlobServiceClient serviceClient = buildServiceClient();
        BlobContainerClient containerClient = serviceClient.getBlobContainerClient(containerName);
        BlobClient blobClient = containerClient.getBlobClient(blobName);

        OffsetDateTime startsOn = OffsetDateTime.now().minusSeconds(30);
        OffsetDateTime expiresOn = OffsetDateTime.now().plusSeconds(expiresInSeconds);

        BlobSasPermission permissions = new BlobSasPermission()
                .setCreatePermission(true)
                .setWritePermission(true)
                .setReadPermission(true); // optional: allow read after upload
        BlobServiceSasSignatureValues signatureValues = new BlobServiceSasSignatureValues(expiresOn, permissions)
                .setStartTime(startsOn);

        String sasToken = blobClient.generateSas(signatureValues);
        String signedUrl = blobClient.getBlobUrl() + "?" + sasToken;

        Map<String, Object> result = new HashMap<>();
        result.put("sasToken", sasToken);
        result.put("signedUrl", signedUrl);
        result.put("expiresOn", expiresOn.toString());

        log.debug("Generated UPLOAD SAS for container={}, blob={}, expiresOn={}", containerName, blobName, expiresOn);
        return result;
    }
}
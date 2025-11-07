package com.pbl6.backend.service;

import com.azure.messaging.servicebus.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.util.HashMap;
import java.util.Map;

@Service
public class AzureQueueService {

    private static final Logger logger = LoggerFactory.getLogger(AzureQueueService.class);

    @Value("${azure.servicebus.connection-string}")
    private String connectionString;

    @Value("${azure.servicebus.queue-name}")
    private String queueName;

    private ServiceBusSenderClient senderClient;
    private final ObjectMapper objectMapper;

    public AzureQueueService() {
        this.objectMapper = new ObjectMapper();
    }

    @PostConstruct
    public void init() {
        try {
            ServiceBusClientBuilder builder = new ServiceBusClientBuilder()
                    .connectionString(connectionString);

            senderClient = builder
                    .sender()
                    .queueName(queueName)
                    .buildClient();

            logger.info("✅ Azure Service Bus Queue sender initialized: {}", queueName);
        } catch (Exception e) {
            logger.error("❌ Failed to initialize Azure Queue sender", e);
            throw new RuntimeException("Failed to connect to Azure Service Bus", e);
        }
    }

    @PreDestroy
    public void cleanup() {
        if (senderClient != null) {
            senderClient.close();
            logger.info("🔒 Azure Service Bus sender closed");
        }
    }

    /**
     * Enqueue a caption generation job to Azure Service Bus Queue
     * 
     * @param jobId       Unique identifier for this job
     * @param postId      Post entity ID
     * @param videoUrl    URL to video file in storage
     * @param mood        User selected mood (e.g., "happy", "sad")
     * @param callbackUrl Full callback URL for AI server to send result
     * @throws Exception if enqueue fails
     */
    public void enqueueCaptionJob(String jobId, String postId, String videoUrl, String mood, String callbackUrl)
            throws Exception {
        Map<String, Object> jobData = new HashMap<>();
        jobData.put("job_id", jobId);
        jobData.put("post_id", postId);
        jobData.put("video_url", videoUrl);
        jobData.put("mood", mood);
        jobData.put("callback_url", callbackUrl);
        jobData.put("timestamp", System.currentTimeMillis());

        String messageBody = objectMapper.writeValueAsString(jobData);
        ServiceBusMessage message = new ServiceBusMessage(messageBody);

        // Set message properties for tracking
        message.setMessageId(jobId);
        message.getApplicationProperties().put("postId", postId);
        message.getApplicationProperties().put("mood", mood);

        senderClient.sendMessage(message);

        logger.info("📤 Enqueued caption job | JobID: {} | PostID: {} | Mood: {} | VideoURL: {}",
                jobId, postId, mood, videoUrl);
    }
}
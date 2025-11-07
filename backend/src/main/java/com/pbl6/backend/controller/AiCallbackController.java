package com.pbl6.backend.controller;

import com.pbl6.backend.request.CaptionResultRequest;
import com.pbl6.backend.service.PostService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/ai/callback")
public class AiCallbackController {

    private static final Logger logger = LoggerFactory.getLogger(AiCallbackController.class);

    private final PostService postService;

    @Value("${ai.caption.callback-secret}")
    private String callbackSecret;

    public AiCallbackController(PostService postService) {
        this.postService = postService;
    }

    /**
     * Callback endpoint for AI Server to send caption results
     * 
     * Expected request body:
     * {
     * "job_id": "550e8400-e29b-41d4-a716-446655440000",
     * "post_id": "123",
     * "success": true,
     * "caption": "A beautiful sunset over mountains",
     * "error_message": null,
     * "secret": "change-me"
     * }
     */
    @PostMapping("/captions")
    public ResponseEntity<Map<String, Object>> receiveCaptionResult(
            @Valid @RequestBody CaptionResultRequest request) {

        logger.info("📥 Received caption callback | JobID: {} | PostID: {} | Success: {}",
                request.getJobId(), request.getPostId(), request.isSuccess());

        // Debug log request details
        logger.debug("🔍 Callback details - Secret: {}, Caption: {}, Error: {}",
                request.getSecret(), request.getCaption(), request.getErrorMessage());

        Map<String, Object> response = new HashMap<>();

        // Validate callback secret to prevent unauthorized requests
        if (!callbackSecret.equals(request.getSecret())) {
            logger.warn("⚠️ Invalid callback secret | JobID: {} | Expected: {} | Received: {}",
                    request.getJobId(), callbackSecret, request.getSecret());
            response.put("success", false);
            response.put("message", "Invalid secret");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        }
        try {
            // Update post with caption result
            postService.updateCaptionResult(
                    request.getPostId(),
                    request.isSuccess(),
                    request.getCaption(),
                    request.getErrorMessage());

            logger.info("✅ Caption updated successfully | PostID: {} | Caption: {}",
                    request.getPostId(),
                    request.getCaption() != null
                            ? request.getCaption().substring(0, Math.min(50, request.getCaption().length()))
                            : "null");

            response.put("success", true);
            response.put("message", "Caption updated successfully");
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            logger.error("❌ Failed to update caption | PostID: {} | Error: {}",
                    request.getPostId(), e.getMessage(), e);
            response.put("success", false);
            response.put("message", "Failed to update caption");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
}
package com.pbl6.backend.controller;

import com.pbl6.backend.request.CaptionCallbackRequest;
import com.pbl6.backend.service.CaptionJobService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ai/callback")
public class AiCallbackController {
    private final CaptionJobService captionJobService;

    @Value("${ai.caption.callback-secret}")
    private String callbackSecret;

    public AiCallbackController(CaptionJobService captionJobService) {
        this.captionJobService = captionJobService;
    }

    @PostMapping("/captions")
    public ResponseEntity<Void> onCaptionCompleted(
            @RequestHeader(value = "X-AI-SECRET", required = false) String secret,
            @Valid @RequestBody CaptionCallbackRequest req
    ) {
        if (callbackSecret != null && !callbackSecret.isBlank()) {
            if (secret == null || !callbackSecret.equals(secret)) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }
        }

        if ("COMPLETED".equalsIgnoreCase(req.getStatus())) {
            captionJobService.markCompleted(req.getJobId(), req.getPostId(), req.getCaption());
        } else {
            String err = req.getError() != null ? req.getError() : "Unknown error";
            captionJobService.markFailed(req.getJobId(), req.getPostId(), err);
        }
        return ResponseEntity.ok().build();
    }
}
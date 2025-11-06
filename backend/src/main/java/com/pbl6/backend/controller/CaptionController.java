package com.pbl6.backend.controller;

import com.pbl6.backend.request.CaptionStartRequest;
import com.pbl6.backend.response.CaptionJobResponse;
import com.pbl6.backend.service.CaptionJobService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/api")
public class CaptionController {
    private final CaptionJobService captionJobService;

    @Value("${ai.caption.callback-path}")
    private String callbackPath;

    public CaptionController(CaptionJobService captionJobService) {
        this.captionJobService = captionJobService;
    }

    // Khởi tạo job sinh caption cho 1 post video
    @PostMapping("/posts/{postId}/captions")
    public ResponseEntity<CaptionJobResponse> startCaption(
            @PathVariable String postId,
            @Valid @RequestBody(required = false) CaptionStartRequest req
    ) {
        String language = req != null ? req.getLanguage() : null;
        String callbackUrl = ServletUriComponentsBuilder
                .fromCurrentContextPath()
                .path(callbackPath)
                .toUriString();

        CaptionJobResponse job = captionJobService.startJob(postId, language, callbackUrl);
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(job);
    }

    // Truy vấn trạng thái job
    @GetMapping("/caption-jobs/{jobId}")
    public ResponseEntity<CaptionJobResponse> getJob(@PathVariable String jobId) {
        return captionJobService.getJob(jobId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
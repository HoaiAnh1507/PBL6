package com.pbl6.backend.controller;

import com.pbl6.backend.model.ModerationReport;
import com.pbl6.backend.request.ResolveReportRequest;
import com.pbl6.backend.request.DeletePostRequest;
import com.pbl6.backend.response.ReportResponse;
import com.pbl6.backend.service.ReportService;
import com.pbl6.backend.service.ModerationService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class ModerationController {

    @Autowired
    private ReportService reportService;

    @Autowired
    private ModerationService moderationService;

    @GetMapping("/reports")
    public ResponseEntity<?> getAllReports(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) ModerationReport.ReportStatus status) {
        
        Pageable pageable = PageRequest.of(page, size);
        Page<ReportResponse> reports = reportService.getAllReports(status, pageable);
        return ResponseEntity.ok(reports);
    }

    @GetMapping("/reports/{reportId}")
    public ResponseEntity<?> getReportById(@PathVariable String reportId) {
        return reportService.getReportById(reportId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/reports/{reportId}/resolve")
    public ResponseEntity<?> resolveReport(
            @PathVariable String reportId,
            @Valid @RequestBody ResolveReportRequest request) {
        
        try {
            ReportResponse response = reportService.resolveReport(
                    reportId, request.getAction(), request.getResolutionNotes());
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @DeleteMapping("/posts/{postId}")
    public ResponseEntity<?> deletePost(
            @PathVariable String postId,
            @Valid @RequestBody DeletePostRequest request) {
        
        try {
            moderationService.deletePost(postId, request.getReason());
            return ResponseEntity.ok().body("Post deleted successfully");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}

package com.pbl6.backend.controller;

import com.pbl6.backend.model.User;
import com.pbl6.backend.request.ReportCreateRequest;
import com.pbl6.backend.response.ReportResponse;
import com.pbl6.backend.service.ReportService;
import com.pbl6.backend.repository.UserRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api/reports")
@CrossOrigin(origins = "*")
public class ReportController {

    @Autowired
    private ReportService reportService;

    @Autowired
    private UserRepository userRepository;

    @PostMapping
    public ResponseEntity<?> createReport(
            Authentication authentication,
            @Valid @RequestBody ReportCreateRequest request) {
        
        if (authentication == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        String username = authentication.getName();
        Optional<User> userOpt = userRepository.findByUsername(username);

        if (userOpt.isEmpty()) {
            return ResponseEntity.status(404).body("Reporter user not found. Username from token: " + username);
        }

        try {
            ReportResponse response = reportService.createReport(
                    userOpt.get(),
                    request.getReportedPostId(),
                    request.getReportedUserId(),
                    request.getReason()
            );
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/my")
    public ResponseEntity<?> getMyReports(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        if (authentication == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        String username = authentication.getName();
        Optional<User> userOpt = userRepository.findByUsername(username);

        if (userOpt.isEmpty()) {
            return ResponseEntity.status(404).body("User not found");
        }

        Pageable pageable = PageRequest.of(page, size);
        Page<ReportResponse> reports = reportService.getReportsByUser(userOpt.get(), pageable);
        
        return ResponseEntity.ok(reports);
    }
}

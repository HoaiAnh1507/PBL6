package com.pbl6.backend.service;

import com.pbl6.backend.model.ModerationReport;
import com.pbl6.backend.model.Post;
import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.ModerationReportRepository;
import com.pbl6.backend.repository.PostRepository;
import com.pbl6.backend.repository.UserRepository;
import com.pbl6.backend.response.ReportResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class ReportService {

    @Autowired
    private ModerationReportRepository reportRepository;

    @Autowired
    private PostRepository postRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public ReportResponse createReport(User reporter, String reportedPostId, String reportedUserId, String reason) {
        if (reportedPostId == null && reportedUserId == null) {
            throw new IllegalArgumentException("Must report either a post or a user");
        }

        ModerationReport report = new ModerationReport();
        report.setReporter(reporter);
        report.setReason(reason);

        if (reportedPostId != null) {
            Optional<Post> postOpt = postRepository.findById(reportedPostId);
            if (postOpt.isEmpty()) {
                throw new IllegalArgumentException("Post not found");
            }
            Post post = postOpt.get();
            report.setReportedPost(post);
            
            // Auto-extract reportedUserId from Post if not provided
            if (reportedUserId == null && post.getUser() != null) {
                report.setReportedUser(post.getUser());
            }
        }

        // If reportedUserId is explicitly provided, use it
        if (reportedUserId != null) {
            Optional<User> userOpt = userRepository.findById(reportedUserId);
            if (userOpt.isEmpty()) {
                throw new IllegalArgumentException("Reported user not found");
            }
            report.setReportedUser(userOpt.get());
        }

        report = reportRepository.save(report);
        return new ReportResponse(report);
    }

    public Page<ReportResponse> getReportsByUser(User reporter, Pageable pageable) {
        Page<ModerationReport> reports = reportRepository.findByReporter(reporter, pageable);
        return reports.map(ReportResponse::new);
    }

    public Page<ReportResponse> getAllReports(ModerationReport.ReportStatus status, Pageable pageable) {
        Page<ModerationReport> reports;
        if (status != null) {
            reports = reportRepository.findByStatus(status, pageable);
        } else {
            reports = reportRepository.findAll(pageable);
        }
        return reports.map(ReportResponse::new);
    }

    public Optional<ReportResponse> getReportById(String reportId) {
        return reportRepository.findById(reportId)
                .map(ReportResponse::new);
    }

    @Transactional
    public ReportResponse resolveReport(String reportId, String action, String resolutionNotes) {
        Optional<ModerationReport> reportOpt = reportRepository.findById(reportId);
        if (reportOpt.isEmpty()) {
            throw new IllegalArgumentException("Report not found");
        }

        ModerationReport report = reportOpt.get();
        
        if ("RESOLVED".equalsIgnoreCase(action)) {
            report.setStatus(ModerationReport.ReportStatus.RESOLVED);
        } else if ("DISMISSED".equalsIgnoreCase(action)) {
            report.setStatus(ModerationReport.ReportStatus.DISMISSED);
        } else {
            throw new IllegalArgumentException("Invalid action. Must be RESOLVED or DISMISSED");
        }

        report.setResolutionNotes(resolutionNotes);
        report.setResolvedAt(java.time.LocalDateTime.now());

        report = reportRepository.save(report);
        return new ReportResponse(report);
    }

    public long countPendingReports() {
        return reportRepository.countByStatus(ModerationReport.ReportStatus.PENDING);
    }
}

package com.pbl6.backend.service;

import com.pbl6.backend.model.Post;
import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.ModerationReportRepository;
import com.pbl6.backend.repository.PostRepository;
import com.pbl6.backend.repository.UserRepository;
import com.pbl6.backend.response.MetricsOverviewResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class MetricsService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PostRepository postRepository;

    @Autowired
    private ModerationReportRepository reportRepository;

    public MetricsOverviewResponse getOverview() {
        MetricsOverviewResponse response = new MetricsOverviewResponse();

        // User metrics
        response.setTotalUsers(userRepository.count());
        response.setActiveUsers(userRepository.countByAccountStatus(User.AccountStatus.ACTIVE));
        response.setSuspendedUsers(userRepository.countByAccountStatus(User.AccountStatus.SUSPENDED));
        response.setBannedUsers(userRepository.countByAccountStatus(User.AccountStatus.BANNED));

        // Post metrics
        response.setTotalPosts(postRepository.count());

        // Report metrics
        response.setPendingReports(reportRepository.countByStatus(
            com.pbl6.backend.model.ModerationReport.ReportStatus.PENDING));

        // AI Performance
        long totalPosts = postRepository.count();
        long successPosts = postRepository.countByCaptionStatus(Post.CaptionStatus.COMPLETED);
        long failedPosts = postRepository.countByCaptionStatus(Post.CaptionStatus.FAILED);
        
        response.setAiPerformance(new MetricsOverviewResponse.AIPerformanceMetrics(
            totalPosts, successPosts, failedPosts));

        return response;
    }

    public List<Map<String, Object>> getUserMetrics(String period) {
        LocalDateTime startDate = getStartDateByPeriod(period);
        return userRepository.findUserCountByDateRange(startDate, LocalDateTime.now());
    }

    public List<Map<String, Object>> getPostMetrics(String period) {
        LocalDateTime startDate = getStartDateByPeriod(period);
        return postRepository.findPostCountByDateRange(startDate, LocalDateTime.now());
    }

    private LocalDateTime getStartDateByPeriod(String period) {
        LocalDateTime now = LocalDateTime.now();
        switch (period) {
            case "7d":
                return now.minusDays(7);
            case "30d":
                return now.minusDays(30);
            case "90d":
                return now.minusDays(90);
            default:
                return now.minusDays(7);
        }
    }
}

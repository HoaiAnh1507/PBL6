package com.pbl6.backend.repository;

import com.pbl6.backend.model.Admin;
import com.pbl6.backend.model.ModerationReport;
import com.pbl6.backend.model.Post;
import com.pbl6.backend.model.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ModerationReportRepository extends JpaRepository<ModerationReport, String> {
    
    List<ModerationReport> findByStatus(ModerationReport.ReportStatus status);
    
    Page<ModerationReport> findByStatus(ModerationReport.ReportStatus status, Pageable pageable);
    
    List<ModerationReport> findByReporter(User reporter);
    
    List<ModerationReport> findByReportedPost(Post reportedPost);
    
    List<ModerationReport> findByReportedUser(User reportedUser);
    
    List<ModerationReport> findByResolvedByAdmin(Admin resolvedByAdmin);
    
    @Query("SELECT mr FROM ModerationReport mr WHERE mr.status = 'PENDING' ORDER BY mr.createdAt ASC")
    List<ModerationReport> findPendingReportsOrderByCreatedAt();
    
    @Query("SELECT mr FROM ModerationReport mr WHERE mr.status = 'PENDING' ORDER BY mr.createdAt ASC")
    Page<ModerationReport> findPendingReportsOrderByCreatedAt(Pageable pageable);
    
    @Query("SELECT mr FROM ModerationReport mr WHERE mr.createdAt BETWEEN :startDate AND :endDate")
    List<ModerationReport> findByCreatedAtBetween(@Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT COUNT(mr) FROM ModerationReport mr WHERE mr.status = :status")
    long countByStatus(@Param("status") ModerationReport.ReportStatus status);
    
    @Query("SELECT COUNT(mr) FROM ModerationReport mr WHERE mr.reporter = :reporter")
    long countByReporter(@Param("reporter") User reporter);
    
    @Query("SELECT COUNT(mr) FROM ModerationReport mr WHERE mr.reportedUser = :reportedUser")
    long countByReportedUser(@Param("reportedUser") User reportedUser);
    
    @Query("SELECT COUNT(mr) FROM ModerationReport mr WHERE mr.reportedPost = :reportedPost")
    long countByReportedPost(@Param("reportedPost") Post reportedPost);
    
    @Query("SELECT COUNT(mr) FROM ModerationReport mr WHERE mr.resolvedByAdmin = :admin")
    long countByResolvedByAdmin(@Param("admin") Admin admin);
}
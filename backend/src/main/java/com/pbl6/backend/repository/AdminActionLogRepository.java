package com.pbl6.backend.repository;

import com.pbl6.backend.model.Admin;
import com.pbl6.backend.model.AdminActionLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AdminActionLogRepository extends JpaRepository<AdminActionLog, Long> {
    
    List<AdminActionLog> findByAdmin(Admin admin);
    
    Page<AdminActionLog> findByAdmin(Admin admin, Pageable pageable);
    
    List<AdminActionLog> findByActionType(String actionType);
    
    List<AdminActionLog> findByTargetId(String targetId);
    
    @Query("SELECT aal FROM AdminActionLog aal WHERE aal.admin = :admin ORDER BY aal.actionTimestamp DESC")
    List<AdminActionLog> findByAdminOrderByActionTimestampDesc(@Param("admin") Admin admin);
    
    @Query("SELECT aal FROM AdminActionLog aal WHERE aal.admin = :admin ORDER BY aal.actionTimestamp DESC")
    Page<AdminActionLog> findByAdminOrderByActionTimestampDesc(@Param("admin") Admin admin, Pageable pageable);
    
    @Query("SELECT aal FROM AdminActionLog aal WHERE aal.actionTimestamp BETWEEN :startDate AND :endDate ORDER BY aal.actionTimestamp DESC")
    List<AdminActionLog> findByActionTimestampBetween(@Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT aal FROM AdminActionLog aal ORDER BY aal.actionTimestamp DESC")
    List<AdminActionLog> findAllOrderByActionTimestampDesc();
    
    @Query("SELECT aal FROM AdminActionLog aal ORDER BY aal.actionTimestamp DESC")
    Page<AdminActionLog> findAllOrderByActionTimestampDesc(Pageable pageable);
    
    @Query("SELECT COUNT(aal) FROM AdminActionLog aal WHERE aal.admin = :admin")
    long countByAdmin(@Param("admin") Admin admin);
    
    @Query("SELECT COUNT(aal) FROM AdminActionLog aal WHERE aal.actionType = :actionType")
    long countByActionType(@Param("actionType") String actionType);
    
    @Query("SELECT aal.actionType, COUNT(aal) FROM AdminActionLog aal GROUP BY aal.actionType")
    List<Object[]> countActionsByType();
}
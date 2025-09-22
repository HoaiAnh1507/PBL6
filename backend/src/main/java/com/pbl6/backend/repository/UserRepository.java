package com.pbl6.backend.repository;

import com.pbl6.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, String> {
    
    Optional<User> findByUsername(String username);
    
    Optional<User> findByPhoneNumber(String phoneNumber);
    
    Optional<User> findByUsernameOrPhoneNumber(String username, String phoneNumber);
    
    boolean existsByUsername(String username);
    
    boolean existsByPhoneNumber(String phoneNumber);
    
    List<User> findByAccountStatus(User.AccountStatus accountStatus);
    
    List<User> findBySubscriptionStatus(User.SubscriptionStatus subscriptionStatus);
    
    @Query("SELECT u FROM User u WHERE u.fullName LIKE %:name%")
    List<User> findByFullNameContaining(@Param("name") String name);
    
    @Query("SELECT u FROM User u WHERE u.username LIKE %:username%")
    List<User> findByUsernameContaining(@Param("username") String username);
    
    @Query("SELECT COUNT(u) FROM User u WHERE u.subscriptionStatus = :status")
    long countBySubscriptionStatus(@Param("status") User.SubscriptionStatus status);
    
    @Query("SELECT COUNT(u) FROM User u WHERE u.accountStatus = :status")
    long countByAccountStatus(@Param("status") User.AccountStatus status);
}
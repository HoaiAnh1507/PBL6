package com.pbl6.backend.repository;

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
public interface PostRepository extends JpaRepository<Post, String> {
    
    List<Post> findByUser(User user);
    
    Page<Post> findByUser(User user, Pageable pageable);
    
    List<Post> findByMediaType(Post.MediaType mediaType);
    
    List<Post> findByCaptionStatus(Post.CaptionStatus captionStatus);
    
    @Query("SELECT p FROM Post p WHERE p.user = :user ORDER BY p.createdAt DESC")
    List<Post> findByUserOrderByCreatedAtDesc(@Param("user") User user);
    
    @Query("SELECT p FROM Post p WHERE p.createdAt BETWEEN :startDate AND :endDate")
    List<Post> findByCreatedAtBetween(@Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT p FROM Post p JOIN p.recipients pr WHERE pr.recipient = :user ORDER BY p.createdAt DESC")
    List<Post> findPostsForUser(@Param("user") User user);
    
    @Query("SELECT p FROM Post p JOIN p.recipients pr WHERE pr.recipient = :user ORDER BY p.createdAt DESC")
    Page<Post> findPostsForUser(@Param("user") User user, Pageable pageable);

    @Query("SELECT p FROM Post p JOIN p.recipients pr WHERE pr.recipient = :recipient AND p.user = :sender ORDER BY p.createdAt DESC")
    List<Post> findPostsForRecipientFromSender(@Param("recipient") User recipient, @Param("sender") User sender);
    
    @Query("SELECT COUNT(p) FROM Post p WHERE p.user = :user")
    long countByUser(@Param("user") User user);
    
    @Query("SELECT COUNT(p) FROM Post p WHERE p.mediaType = :mediaType")
    long countByMediaType(@Param("mediaType") Post.MediaType mediaType);
}
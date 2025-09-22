package com.pbl6.backend.repository;

import com.pbl6.backend.model.Post;
import com.pbl6.backend.model.PostReaction;
import com.pbl6.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PostReactionRepository extends JpaRepository<PostReaction, String> {
    
    List<PostReaction> findByPost(Post post);
    
    List<PostReaction> findByUser(User user);
    
    Optional<PostReaction> findByPostAndUser(Post post, User user);
    
    List<PostReaction> findByPostAndEmojiType(Post post, String emojiType);
    
    @Query("SELECT COUNT(pr) FROM PostReaction pr WHERE pr.post = :post")
    long countByPost(@Param("post") Post post);
    
    @Query("SELECT COUNT(pr) FROM PostReaction pr WHERE pr.post = :post AND pr.emojiType = :emojiType")
    long countByPostAndEmojiType(@Param("post") Post post, @Param("emojiType") String emojiType);
    
    @Query("SELECT pr.emojiType, COUNT(pr) FROM PostReaction pr WHERE pr.post = :post GROUP BY pr.emojiType")
    List<Object[]> countReactionsByPost(@Param("post") Post post);
    
    boolean existsByPostAndUser(Post post, User user);
    
    void deleteByPostAndUser(Post post, User user);
    
    void deleteByPost(Post post);
}
package com.pbl6.backend.repository;

import com.pbl6.backend.model.Post;
import com.pbl6.backend.model.PostReaction;
import com.pbl6.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PostReactionRepository extends JpaRepository<PostReaction, String> {
    
    List<PostReaction> findByPost(Post post);
    
    List<PostReaction> findByUser(User user);
    
    Optional<PostReaction> findByPostAndUser(Post post, User user);

    // Hỗ trợ nhiều reaction của một user cho một post
    List<PostReaction> findAllByPostAndUser(Post post, User user);

    boolean existsByPostAndUserAndEmojiType(Post post, User user, String emojiType);
    
    List<PostReaction> findByPostAndEmojiType(Post post, String emojiType);
    
    // removed unused count queries per simplified reaction requirements
    
    boolean existsByPostAndUser(Post post, User user);
    
    void deleteByPostAndUser(Post post, User user);
    
    void deleteByPost(Post post);
}
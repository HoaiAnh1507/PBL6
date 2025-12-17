package com.pbl6.backend.service;

import com.pbl6.backend.model.Post;
import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.PostRepository;
import com.pbl6.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class ModerationService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PostRepository postRepository;

    @Transactional
    public User updateUserStatus(String userId, String statusString, String reason) {
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            throw new IllegalArgumentException("User not found");
        }

        User user = userOpt.get();
        
        // Convert string to AccountStatus enum
        User.AccountStatus status;
        try {
            status = User.AccountStatus.valueOf(statusString.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid status. Must be ACTIVE, SUSPENDED, or BANNED");
        }
        
        user.setAccountStatus(status);
        
        return userRepository.save(user);
    }

    @Transactional
    public void deletePost(String postId, String reason) {
        Optional<Post> postOpt = postRepository.findById(postId);
        if (postOpt.isEmpty()) {
            throw new IllegalArgumentException("Post not found");
        }

        Post post = postOpt.get();
        post.setIsDeleted(true);
        post.setDeletedAt(LocalDateTime.now());
        postRepository.save(post);
    }

    public Optional<Post> getPostById(String postId) {
        return postRepository.findById(postId);
    }
}

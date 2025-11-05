package com.pbl6.backend.service;

import com.pbl6.backend.model.Post;
import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.PostRepository;
import com.pbl6.backend.repository.UserRepository;
import com.pbl6.backend.request.AiCaptionInitRequest;
import com.pbl6.backend.request.PostDirectCreateRequest;
import com.pbl6.backend.request.PostFinalizeRequest;
import com.pbl6.backend.response.AiCaptionInitResponse;
import com.pbl6.backend.response.PostReactionResponse;
import com.pbl6.backend.response.PostResponse;
import com.pbl6.backend.response.UserResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.Optional;

@Service
public class PostService {
    private static final Logger log = LoggerFactory.getLogger(PostService.class);

    private final PostRepository postRepository;
    private final UserRepository userRepository;

    public PostService(PostRepository postRepository, UserRepository userRepository) {
        this.postRepository = postRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public AiCaptionInitResponse initAiCaption(User user, AiCaptionInitRequest req) {
        Post.MediaType mediaType = parseMediaType(req.getMediaType());

        String aiCaption = generateCaptionStub(mediaType, req.getMediaUrl());

        Post post = new Post(user, mediaType, req.getMediaUrl());
        post.setGeneratedCaption(aiCaption);
        post.setCaptionStatus(Post.CaptionStatus.PENDING);
        post.setUserEditedCaption(null);

        post = postRepository.save(post);
        log.info("AI init tạo Post: id={}, status={}, generatedCaption={}", post.getPostId(), post.getCaptionStatus(), post.getGeneratedCaption());

        return new AiCaptionInitResponse(post.getPostId(), post.getGeneratedCaption());
    }

    @Transactional
    public Post finalizePost(PostFinalizeRequest req) {
        Post post = postRepository.findById(req.getPostId())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy post với id=" + req.getPostId()));

        post.setUserEditedCaption(req.getFinalCaption());
        post.setCaptionStatus(Post.CaptionStatus.COMPLETED);
        Post saved = postRepository.save(post);
        log.info("Finalize Post: id={}, status={}, finalCaptionLength={}", saved.getPostId(), saved.getCaptionStatus(), 
                Optional.ofNullable(saved.getUserEditedCaption()).map(String::length).orElse(0));
        return saved;
    }

    @Transactional
    public Post createDirect(User user, PostDirectCreateRequest req) {
        Post.MediaType mediaType = parseMediaType(req.getMediaType());

        Post post = new Post(user, mediaType, req.getMediaUrl());
        post.setGeneratedCaption(null);
        post.setUserEditedCaption(req.getFinalCaption());
        post.setCaptionStatus(Post.CaptionStatus.COMPLETED);

        post = postRepository.save(post);
        log.info("Create Direct Post: id={}, status={}, hasCaption={}", post.getPostId(), post.getCaptionStatus(), post.getUserEditedCaption() != null);
        return post;
    }

    @Transactional
    public void deletePost(String postId) {
        if (!postRepository.existsById(postId)) {
            throw new IllegalArgumentException("Không tìm thấy post với id=" + postId);
        }
        postRepository.deleteById(postId);
        log.info("Đã xóa Post id={}", postId);
    }

    public PostResponse toResponse(Post post) {
        User u = post.getUser();
        UserResponse ur = new UserResponse(
                u.getUserId(),
                u.getUsername(),
                u.getFullName(),
                u.getPhoneNumber(),
                null,
                u.getProfilePictureUrl(),
                u.getAccountStatus().name(),
                u.getSubscriptionStatus().name(),
                u.getCreatedAt()
        );

        return new PostResponse(
                post.getPostId(),
                ur,
                post.getUserEditedCaption(),
                post.getMediaType().name(),
                post.getMediaUrl(),
                post.getCaptionStatus().name(),
                post.getCreatedAt(),
                Collections.emptyList(),
                Collections.<PostReactionResponse>emptyList(),
                0
        );
    }

    private Post.MediaType parseMediaType(String mediaType) {
        try {
            return Post.MediaType.valueOf(mediaType.toUpperCase());
        } catch (Exception e) {
            throw new IllegalArgumentException("mediaType không hợp lệ: " + mediaType + ". Chỉ hỗ trợ PHOTO|VIDEO");
        }
    }

    // Stub sinh caption AI - sẽ thay bằng tích hợp thật sau này
    private String generateCaptionStub(Post.MediaType type, String mediaUrl) {
        String kind = type == Post.MediaType.PHOTO ? "ảnh" : "video";
        return "Caption AI cho " + kind + " — " + (mediaUrl.length() > 50 ? mediaUrl.substring(0, 50) + "..." : mediaUrl);
    }
}
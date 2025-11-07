package com.pbl6.backend.service;

import com.pbl6.backend.model.Post;
import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.PostRepository;
import com.pbl6.backend.repository.PostRecipientRepository;
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
import java.util.List;
import java.util.ArrayList;

@Service
public class PostService {
    private static final Logger log = LoggerFactory.getLogger(PostService.class);

    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final PostRecipientRepository postRecipientRepository;

    public PostService(PostRepository postRepository, UserRepository userRepository, PostRecipientRepository postRecipientRepository) {
        this.postRepository = postRepository;
        this.userRepository = userRepository;
        this.postRecipientRepository = postRecipientRepository;
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

        // Cập nhật recipients nếu có
        setRecipients(saved, req.getRecipientIds());
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

        // Lưu recipients nếu có
        setRecipients(post, req.getRecipientIds());
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

        List<UserResponse> recipientResponses = new ArrayList<>();
        try {
            List<User> recipients = postRecipientRepository.findRecipientsByPost(post);
            for (User r : recipients) {
                recipientResponses.add(new UserResponse(
                        r.getUserId(),
                        r.getUsername(),
                        r.getFullName(),
                        r.getPhoneNumber(),
                        null,
                        r.getProfilePictureUrl(),
                        r.getAccountStatus().name(),
                        r.getSubscriptionStatus().name(),
                        r.getCreatedAt()
                ));
            }
        } catch (Exception e) {
            log.warn("Không thể lấy recipients cho post {}: {}", post.getPostId(), e.getMessage());
        }

        return new PostResponse(
                post.getPostId(),
                ur,
                post.getUserEditedCaption(),
                post.getMediaType().name(),
                post.getMediaUrl(),
                post.getCaptionStatus().name(),
                post.getCreatedAt(),
                recipientResponses,
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

    private void setRecipients(Post post, List<String> recipientIds) {
        if (recipientIds == null || recipientIds.isEmpty()) {
            return;
        }
        // Xóa recipients cũ để đặt lại danh sách
        postRecipientRepository.deleteByPost(post);
        int added = 0;
        for (String rid : recipientIds) {
            if (rid == null || rid.isBlank()) continue;
            Optional<User> ru = userRepository.findById(rid);
            if (ru.isEmpty()) {
                log.warn("Bỏ qua recipientId không tồn tại: {}", rid);
                continue;
            }
            User recipient = ru.get();
            if (postRecipientRepository.existsByPostAndRecipient(post, recipient)) {
                continue;
            }
            postRecipientRepository.save(new com.pbl6.backend.model.PostRecipient(post, recipient));
            added++;
        }
        log.info("Đã set {} recipients cho post {}", added, post.getPostId());
    }
}
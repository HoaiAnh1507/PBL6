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
import com.pbl6.backend.response.CaptionStatusResponse;
import com.pbl6.backend.response.PostReactionResponse;
import com.pbl6.backend.response.PostResponse;
import com.pbl6.backend.response.UserResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.Optional;
import java.util.UUID;
import java.util.List;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.stream.Collectors;

@Service
public class PostService {
    private static final Logger log = LoggerFactory.getLogger(PostService.class);

    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final PostRecipientRepository postRecipientRepository;
    private final AzureQueueService azureQueueService;

    @Value("${server.port:8080}")
    private String serverPort;

    public PostService(PostRepository postRepository,
            UserRepository userRepository,
            PostRecipientRepository postRecipientRepository,
            AzureQueueService azureQueueService) {
        this.postRepository = postRepository;
        this.userRepository = userRepository;
        this.postRecipientRepository = postRecipientRepository;
        this.azureQueueService = azureQueueService;
    }

    @Transactional
    public AiCaptionInitResponse initAiCaption(User user, AiCaptionInitRequest req) {
        Post.MediaType mediaType = parseMediaType(req.getMediaType());

        // Create post with PENDING status
        Post post = new Post(user, mediaType, req.getMediaUrl());
        post.setGeneratedCaption(null); // Will be set by callback
        post.setCaptionStatus(Post.CaptionStatus.PENDING);
        
        post = postRepository.save(post);
        log.info("✅ Created Post for AI caption | PostID: {} | MediaType: {} | Status: {}",
                post.getPostId(), mediaType, Post.CaptionStatus.PENDING);

        // Enqueue job to Azure Service Bus
        try {
            String jobId = UUID.randomUUID().toString();
            String mood = req.getMood() != null ? req.getMood() : "neutral";
            String callbackUrl = buildCallbackUrl();

            azureQueueService.enqueueCaptionJob(
                    jobId,
                    post.getPostId(),
                    req.getMediaUrl(),
                    mood,
                    callbackUrl);

            log.info("📤 Enqueued AI caption job | PostID: {} | JobID: {} | Mood: {}",
                    post.getPostId(), jobId, mood);

        } catch (Exception e) {
            log.error("❌ Failed to enqueue caption job | PostID: {}", post.getPostId(), e);
            // Mark as FAILED if can't enqueue
            post.setCaptionStatus(Post.CaptionStatus.FAILED);
            post = postRepository.save(post);
            throw new RuntimeException("Failed to enqueue caption generation job", e);
        }

        return new AiCaptionInitResponse(post.getPostId(), null); // Caption will come via callback
    }

    /**
     * Update post with caption result from AI Server callback
     */
    @Transactional
    public void updateCaptionResult(String postId, boolean success, String caption, String errorMessage) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Post not found: " + postId));

        if (success && caption != null) {
            post.setGeneratedCaption(caption);
            post.setCaptionStatus(Post.CaptionStatus.COMPLETED);
            log.info("✅ Caption updated successfully | PostID: {} | Caption: {}",
                    postId, caption.substring(0, Math.min(50, caption.length())));
        } else {
            post.setGeneratedCaption(null);
            post.setCaptionStatus(Post.CaptionStatus.FAILED);
            log.warn("⚠️ Caption generation failed | PostID: {} | Error: {}", postId, errorMessage);
        }

        postRepository.save(post);
    }

    /**
     * Get caption status for mobile polling
     */
    public CaptionStatusResponse getCaptionStatus(String postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Post not found: " + postId));

        return new CaptionStatusResponse(
                post.getCaptionStatus().name(),
                post.getGeneratedCaption() != null,
                post.getGeneratedCaption(),
                post.getCaptionStatus() == Post.CaptionStatus.FAILED ? "Caption generation failed. Please try again."
                        : null);
    }

    private String buildCallbackUrl() {
        // For local development
        return "http://localhost:" + serverPort + "/api/ai/callback/captions";
    }

    @Transactional
    public Post finalizePost(PostFinalizeRequest req) {
        Post post = postRepository.findById(req.getPostId())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy post với id=" + req.getPostId()));

        post.setFinalCaption(req.getFinalCaption());
        post.setCaptionStatus(Post.CaptionStatus.COMPLETED);
        Post saved = postRepository.save(post);

        // Cập nhật recipients nếu có
        setRecipients(saved, req.getRecipientIds());
        log.info("Finalize Post: id={}, status={}, finalCaptionLength={}", saved.getPostId(), saved.getCaptionStatus(),
                Optional.ofNullable(saved.getFinalCaption()).map(String::length).orElse(0));
        return saved;
    }

    @Transactional
    public Post createDirect(User user, PostDirectCreateRequest req) {
        Post.MediaType mediaType = parseMediaType(req.getMediaType());

        Post post = new Post(user, mediaType, req.getMediaUrl());
        post.setGeneratedCaption(null);
        post.setFinalCaption(req.getFinalCaption());
        post.setCaptionStatus(Post.CaptionStatus.COMPLETED);

        post = postRepository.save(post);

        // Lưu recipients nếu có
        setRecipients(post, req.getRecipientIds());
        log.info("Create Direct Post: id={}, status={}, hasCaption={}", post.getPostId(), post.getCaptionStatus(),
                post.getFinalCaption() != null);
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
                null,
                u.getProfilePictureUrl(),
                u.getAccountStatus().name(),
                u.getSubscriptionStatus().name(),
                u.getCreatedAt());

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
                        null,
                        r.getProfilePictureUrl(),
                        r.getAccountStatus().name(),
                        r.getSubscriptionStatus().name(),
                        r.getCreatedAt()));
            }
        } catch (Exception e) {
            log.warn("Không thể lấy recipients cho post {}: {}", post.getPostId(), e.getMessage());
        }

        return new PostResponse(
                post.getPostId(),
                ur,
                post.getFinalCaption(),
                post.getMediaType().name(),
                post.getMediaUrl(),
                post.getCaptionStatus().name(),
                post.getCreatedAt(),
                recipientResponses,
                Collections.<PostReactionResponse>emptyList(),
                0);
    }

    /**
     * Lấy feed cho người dùng: gồm bài tôi đăng và bài người khác chia sẻ cho tôi.
     */
    @Transactional(readOnly = true)
    public List<PostResponse> listMyFeed(User me) {
        List<Post> myPosts = postRepository.findByUserOrderByCreatedAtDesc(me);
        List<Post> sharedToMe = postRepository.findPostsForUser(me);

        List<Post> combined = new ArrayList<>();
        combined.addAll(myPosts);
        combined.addAll(sharedToMe);

        // Loại trùng theo postId và sắp xếp mới nhất trước
        List<Post> dedupSorted = combined.stream()
                .collect(Collectors.toMap(Post::getPostId, p -> p, (p1, p2) -> p1))
                .values()
                .stream()
                .sorted(Comparator.comparing(Post::getCreatedAt).reversed())
                .collect(Collectors.toList());

        return dedupSorted.stream().map(this::toResponse).collect(Collectors.toList());
    }

    /**
     * Lấy các bài đăng được chia sẻ cho tôi từ một người dùng cụ thể.
     */
    @Transactional(readOnly = true)
    public List<PostResponse> listSharedToMeFrom(User me, String fromUsername) {
        User fromUser = userRepository.findByUsername(fromUsername)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng: " + fromUsername));

        List<Post> posts = postRepository.findPostsForRecipientFromSender(me, fromUser);
        return posts.stream()
                .sorted(Comparator.comparing(Post::getCreatedAt).reversed())
                .map(this::toResponse)
                .collect(Collectors.toList());
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
        return "Caption AI cho " + kind + " — "
                + (mediaUrl.length() > 50 ? mediaUrl.substring(0, 50) + "..." : mediaUrl);
    }

    private void setRecipients(Post post, List<String> recipientIds) {
        if (recipientIds == null || recipientIds.isEmpty()) {
            return;
        }
        // Xóa recipients cũ để đặt lại danh sách
        postRecipientRepository.deleteByPost(post);
        int added = 0;
        for (String rid : recipientIds) {
            if (rid == null || rid.isBlank())
                continue;
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
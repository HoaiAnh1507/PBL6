package com.pbl6.backend.service;

import com.pbl6.backend.model.Post;
import com.pbl6.backend.model.PostReaction;
import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.PostRepository;
import com.pbl6.backend.repository.PostRecipientRepository;
import com.pbl6.backend.repository.PostReactionRepository;
import com.pbl6.backend.repository.UserRepository;
import com.pbl6.backend.request.AiCaptionInitRequest;
import com.pbl6.backend.request.PostDirectCreateRequest;
import com.pbl6.backend.request.PostFinalizeRequest;
import com.pbl6.backend.response.AiCaptionInitResponse;
import com.pbl6.backend.response.CaptionStatusResponse;
import com.pbl6.backend.response.PostReactionResponse;
import com.pbl6.backend.response.PostResponse;
// removed unused stats response
import com.pbl6.backend.response.PostOwnReactionsResponse;
import com.pbl6.backend.response.PostReactionsDetailedResponse;
import com.pbl6.backend.response.PostUserReactions;
import com.pbl6.backend.request.PostReactionRequest;
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
    private final PostReactionRepository postReactionRepository;
    private final AzureQueueService azureQueueService;

    @Value("${server.port:8080}")
    private String serverPort;

    public PostService(PostRepository postRepository,
            UserRepository userRepository,
            PostRecipientRepository postRecipientRepository,
            AzureQueueService azureQueueService,
            PostReactionRepository postReactionRepository) {
        this.postRepository = postRepository;
        this.userRepository = userRepository;
        this.postRecipientRepository = postRecipientRepository;
        this.azureQueueService = azureQueueService;
        this.postReactionRepository = postReactionRepository;
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
     * Lấy feed với cursor-based pagination (Lazy Loading + Infinite Scrolling).
     * Feed bao gồm: bài đăng của bản thân + bài được chia sẻ cho mình.
     * @param me người dùng hiện tại
     * @param beforePostId ID của post cũ nhất trong list hiện tại (cursor)
     * @param limit số lượng posts (default 20, max 50)
     * @return danh sách posts (cả của mình và được share), sắp xếp giảm dần theo thời gian (mới → cũ)
     */
    @Transactional(readOnly = true)
    public List<PostResponse> getFeedWithPagination(User me, String beforePostId, Integer limit) {
        // Validate và set default limit
        int pageSize = (limit == null || limit <= 0) ? 20 : Math.min(limit, 50);

        List<Post> posts;
        if (beforePostId != null && !beforePostId.isBlank()) {
            // Load posts cũ hơn (scroll xuống) - Cursor-based
            Post beforePost = postRepository.findById(beforePostId)
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy post với id=" + beforePostId));
            posts = postRepository.findPostsForUserBeforeTime(me, beforePost.getCreatedAt())
                    .stream()
                    .limit(pageSize)
                    .collect(Collectors.toList());
        } else {
            // Load posts mới nhất - Initial load
            posts = postRepository.findTopNPostsForUser(me)
                    .stream()
                    .limit(pageSize)
                    .collect(Collectors.toList());
        }

        // Convert to response
        return posts.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lấy feed cho người dùng: gồm bài tôi đăng và bài người khác chia sẻ cho tôi.
     * @deprecated Sử dụng getFeedWithPagination() thay thế để tối ưu hiệu năng
     */
    @Deprecated
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

    // --- Reactions ---

    @Transactional
    public PostOwnReactionsResponse reactToPost(User reactor, String postId, String emojiType) {
        String normalized = normalizeEmojiType(emojiType);

        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy post với id=" + postId));

        // Không cho react bài post của chính mình
        if (reactor.getUserId().equals(post.getUser().getUserId())) {
            throw new RuntimeException("Bạn không thể react bài đăng của chính mình");
        }
        // Chỉ cho phép người nhận
        boolean allowed = postRecipientRepository.existsByPostAndRecipient(post, reactor);
        if (!allowed) {
            throw new RuntimeException("Bạn không có quyền react bài đăng này");
        }

        // Nếu đã có reaction trùng loại bởi user trên post này -> no-op, trả về reactions của chính người dùng
        if (postReactionRepository.existsByPostAndUserAndEmojiType(post, reactor, normalized)) {
            return getOwnReactionsForPost(reactor, postId);
        }

        // Giới hạn tối đa 3 reaction cho mỗi (post, user)
        List<PostReaction> myReactions = postReactionRepository.findAllByPostAndUser(post, reactor);
        if (myReactions.size() >= 3) {
            // Xóa reaction cũ nhất
            myReactions.stream()
                    .sorted(java.util.Comparator.comparing(PostReaction::getCreatedAt))
                    .findFirst()
                    .ifPresent(old -> postReactionRepository.deleteById(old.getReactionId()));
        }

        // Thêm reaction mới
        PostReaction pr = new PostReaction(post, reactor, normalized);
        postReactionRepository.save(pr);

        return getOwnReactionsForPost(reactor, postId);
    }

    // Removed owner stats endpoints per new requirements (chỉ hiển thị reaction của bản thân)

    private String normalizeEmojiType(String emojiType) {
        if (emojiType == null) {
            throw new IllegalArgumentException("emojiType không được để trống");
        }
        String v = emojiType.trim().toLowerCase();
        java.util.Set<String> allowed = java.util.Set.of("like", "love", "haha", "wow", "sad",
                "angry", "care", "fire", "clap", "100", "star", "cry_laugh", "heart_broken", "party", "mind_blown");
        if (!allowed.contains(v)) {
            throw new IllegalArgumentException("emojiType không hợp lệ: " + emojiType);
        }
        return v;
    }

    // --- Own reactions by viewer ---
    @Transactional(readOnly = true)
    public PostOwnReactionsResponse getOwnReactionsForPost(User viewer, String postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy post với id=" + postId));

        // Người xem phải là chủ bài đăng hoặc nằm trong recipients
        boolean allowed = post.getUser().getUserId().equals(viewer.getUserId())
                || postRecipientRepository.existsByPostAndRecipient(post, viewer);
        if (!allowed) {
            throw new RuntimeException("Bạn không có quyền xem reactions của mình trên bài đăng này");
        }

        List<PostReaction> myReactions = postReactionRepository.findAllByPostAndUser(post, viewer);
        java.util.List<String> types = myReactions.stream()
                .sorted(java.util.Comparator.comparing(PostReaction::getCreatedAt))
                .map(PostReaction::getEmojiType)
                .collect(java.util.stream.Collectors.toList());

        return new PostOwnReactionsResponse(post.getPostId(), types);
    }

    // --- All reactions for owner ---
    @Transactional(readOnly = true)
    public PostReactionsDetailedResponse getAllReactionsForOwner(User viewer, String postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy post với id=" + postId));

        boolean isOwner = post.getUser().getUserId().equals(viewer.getUserId());
        if (!isOwner) {
            throw new RuntimeException("Chỉ chủ bài đăng mới được xem tất cả reactions");
        }

        java.util.List<PostReaction> reactions = postReactionRepository.findByPost(post);
        reactions.sort(java.util.Comparator.comparing(PostReaction::getCreatedAt));

        java.util.Map<String, java.util.List<String>> emojisByUser = new java.util.HashMap<>();
        java.util.Map<String, com.pbl6.backend.model.User> userById = new java.util.HashMap<>();
        for (PostReaction r : reactions) {
            com.pbl6.backend.model.User u = r.getUser();
            String uid = u.getUserId();
            userById.putIfAbsent(uid, u);
            emojisByUser.computeIfAbsent(uid, k -> new java.util.ArrayList<>()).add(r.getEmojiType());
        }

        java.util.List<PostUserReactions> items = new java.util.ArrayList<>();
        for (java.util.Map.Entry<String, java.util.List<String>> e : emojisByUser.entrySet()) {
            com.pbl6.backend.model.User u = userById.get(e.getKey());
            items.add(new PostUserReactions(
                    u.getUserId(),
                    u.getUsername(),
                    u.getFullName(),
                    u.getProfilePictureUrl(),
                    e.getValue()
            ));
        }
        // Tuỳ chọn: có thể sắp xếp danh sách users theo tên hoặc số lượng reactions

        return new PostReactionsDetailedResponse(post.getPostId(), items);
    }
}
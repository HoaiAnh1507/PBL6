package com.pbl6.backend.controller;

import com.pbl6.backend.model.Post;
import com.pbl6.backend.security.CustomUserDetailsService;
import com.pbl6.backend.request.AiCaptionInitRequest;
import com.pbl6.backend.request.PostDirectCreateRequest;
import com.pbl6.backend.request.PostFinalizeRequest;
import com.pbl6.backend.response.AiCaptionInitResponse;
import com.pbl6.backend.response.CaptionStatusResponse;
import com.pbl6.backend.response.PostResponse;
import com.pbl6.backend.service.PostService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/posts")
public class PostController {
    private static final Logger log = LoggerFactory.getLogger(PostController.class);

    private final PostService postService;

    public PostController(PostService postService) {
        this.postService = postService;
    }

    private CustomUserDetailsService.CustomUserPrincipal getCurrentPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new RuntimeException("Chưa xác thực");
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof CustomUserDetailsService.CustomUserPrincipal userPrincipal) {
            return userPrincipal;
        }
        throw new RuntimeException("Không thể xác thực người dùng");
    }

    // 1. Khởi tạo caption AI: tạo Post với generated_caption và post_status=PENDING
    @PostMapping("/ai/init")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<AiCaptionInitResponse> initAiCaption(@Valid @RequestBody AiCaptionInitRequest req) {
        var principal = getCurrentPrincipal();
        AiCaptionInitResponse resp = postService.initAiCaption(principal.getUser(), req);
        return ResponseEntity.ok(resp);
    }

    // 1b. Người dùng nhấn đăng: cập nhật final_caption và post_status=COMPLETED
    @PostMapping("/ai/commit")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> commitPost(@Valid @RequestBody PostFinalizeRequest req) {

        Post updated = postService.finalizePost(req);
        return ResponseEntity.ok(Map.of(
                "postId", updated.getPostId(),
                "postStatus", updated.getCaptionStatus().name()));

    }

    // 1c. Người dùng hủy: xóa post theo postId
    @DeleteMapping("/{postId}")
    public ResponseEntity<Map<String, String>> deletePost(@PathVariable String postId) {
        postService.deletePost(postId);
        return ResponseEntity.ok(Map.of("deleted", postId));
    }

    // 1d. Mobile polling: check caption generation status
    @GetMapping("/{postId}/caption-status")
    public ResponseEntity<CaptionStatusResponse> getCaptionStatus(@PathVariable String postId) {
        CaptionStatusResponse status = postService.getCaptionStatus(postId);
        return ResponseEntity.ok(status);
    }

    // 2. Đăng trực tiếp (không AI): tạo Post với generated_caption=null,
    // final_caption theo người dùng, post_status=COMPLETED
    @PostMapping
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<PostResponse> createDirect(@Valid @RequestBody PostDirectCreateRequest req) {
        var principal = getCurrentPrincipal();
        Post post = postService.createDirect(principal.getUser(), req);
        return ResponseEntity.ok(postService.toResponse(post));
    }

    // POST /api/posts/{id}/reactions: thả cảm xúc vào bài đăng của bạn bè
    @PostMapping("/{postId}/reactions")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> addReaction(@PathVariable String postId,
                                         @Valid @RequestBody com.pbl6.backend.request.PostReactionRequest req) {
        var principal = getCurrentPrincipal();
        try {
            var own = postService.reactToPost(principal.getUser(), postId, req.getEmojiType());
            return ResponseEntity.ok(own);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (RuntimeException e) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Đã xảy ra lỗi khi thêm reaction"));
        }
    }

    // GET /api/posts/{id}/reactions: chủ bài xem tất cả, người khác chỉ xem của bản thân
    @GetMapping("/{postId}/reactions")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> getReactionStats(@PathVariable String postId) {
        var principal = getCurrentPrincipal();
        try {
            // Nếu là chủ bài đăng: trả về tất cả reactions theo danh sách đối tượng chi tiết
            try {
                var all = postService.getAllReactionsForOwner(principal.getUser(), postId);
                return ResponseEntity.ok(all);
            } catch (RuntimeException ownerOnly) {
                // Không phải chủ -> trả về reactions của chính người xem
                if (ownerOnly.getMessage() != null && ownerOnly.getMessage().contains("Chỉ chủ bài đăng")) {
                    var own = postService.getOwnReactionsForPost(principal.getUser(), postId);
                    return ResponseEntity.ok(own);
                }
                throw ownerOnly;
            }
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (RuntimeException e) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Đã xảy ra lỗi khi lấy reactions của bạn"));
        }
    }

    // 3. Feed của tôi: bài tôi đăng + bài người khác chia sẻ cho tôi
    @GetMapping("/feed")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<List<PostResponse>> myFeed() {
        var principal = getCurrentPrincipal();
        List<PostResponse> feed = postService.listMyFeed(principal.getUser());
        return ResponseEntity.ok(feed);
    }

    // 4. Các bài được chia sẻ cho tôi từ một người dùng cụ thể
    @GetMapping("/shared-to-me/from/{username}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<List<PostResponse>> sharedToMeFrom(@PathVariable String username) {
        var principal = getCurrentPrincipal();
        List<PostResponse> posts = postService.listSharedToMeFrom(principal.getUser(), username);
        return ResponseEntity.ok(posts);
    }
}
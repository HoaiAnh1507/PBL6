package com.pbl6.backend.controller;

import com.pbl6.backend.model.Post;
import com.pbl6.backend.security.CustomUserDetailsService;
import com.pbl6.backend.request.AiCaptionInitRequest;
import com.pbl6.backend.request.PostDirectCreateRequest;
import com.pbl6.backend.request.PostFinalizeRequest;
import com.pbl6.backend.response.AiCaptionInitResponse;
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
    public ResponseEntity<Map<String, String>> commitPost(@Valid @RequestBody PostFinalizeRequest req) {
        
            Post updated = postService.finalizePost(req);
            return ResponseEntity.ok(Map.of(
                    "postId", updated.getPostId(),
                    "postStatus", updated.getCaptionStatus().name()
            ));
        
    }

    // 1c. Người dùng hủy: xóa post theo postId
    @DeleteMapping("/{postId}")
    public ResponseEntity<Map<String, String>> deletePost(@PathVariable String postId) {
        postService.deletePost(postId);
        return ResponseEntity.ok(Map.of("deleted", postId));
    }

    // 2. Đăng trực tiếp (không AI): tạo Post với generated_caption=null, final_caption theo người dùng, post_status=COMPLETED
    @PostMapping
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<PostResponse> createDirect(@Valid @RequestBody PostDirectCreateRequest req) {
        var principal = getCurrentPrincipal();
        Post post = postService.createDirect(principal.getUser(), req);
        return ResponseEntity.ok(postService.toResponse(post));
    }
}
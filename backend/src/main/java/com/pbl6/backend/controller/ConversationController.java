package com.pbl6.backend.controller;

import com.pbl6.backend.response.ConversationResponse;
import com.pbl6.backend.security.CustomUserDetailsService;
import com.pbl6.backend.service.ConversationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/conversations")
public class ConversationController {
    private static final Logger log = LoggerFactory.getLogger(ConversationController.class);

    private final ConversationService conversationService;

    public ConversationController(ConversationService conversationService) {
        this.conversationService = conversationService;
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

    // GET /api/conversations: danh sách hội thoại của tôi
    @GetMapping
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<List<ConversationResponse>> listMyConversations() {
        var principal = getCurrentPrincipal();
        List<ConversationResponse> res = conversationService.listMyConversations(principal.getUser());
        return ResponseEntity.ok(res);
    }

    // GET /api/conversations/{conversationId}: xem thông tin hội thoại (không bao gồm messages)
    @GetMapping("/{conversationId}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<ConversationResponse> getMyConversation(@PathVariable String conversationId) {
        var principal = getCurrentPrincipal();
        ConversationResponse res = conversationService.getMyConversation(principal.getUser(), conversationId);
        return ResponseEntity.ok(res);
    }

    /**
     * GET /api/conversations/{conversationId}/messages: lấy tin nhắn với pagination
     * Query params:
     * - beforeMessageId (optional): load tin nhắn cũ hơn tin này (dùng khi scroll lên)
     * - limit (optional): số lượng tin (default 25, max 100)
     * 
     * Response: List<MessageResponse> sắp xếp tăng dần theo thời gian (cũ → mới)
     * 
     * Cách sử dụng:
     * 1. Lần đầu load: GET /messages (không có params) → 25 tin mới nhất
     * 2. Scroll lên load cũ hơn: GET /messages?beforeMessageId=<id_tin_cu_nhat>&limit=25
     */
    @GetMapping("/{conversationId}/messages")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> getConversationMessages(
            @PathVariable String conversationId,
            @RequestParam(required = false) String beforeMessageId,
            @RequestParam(required = false) Integer limit) {
        try {
            var principal = getCurrentPrincipal();
            var messages = conversationService.getConversationMessages(
                    principal.getUser(), conversationId, beforeMessageId, limit);
            return ResponseEntity.ok(messages);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new java.util.HashMap<String, String>() {{
                put("error", e.getMessage());
            }});
        }
    }
}
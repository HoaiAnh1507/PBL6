package com.pbl6.backend.controller;

import com.pbl6.backend.request.MessageSendRequest;
import com.pbl6.backend.request.ReplyPostMessageRequest;
import com.pbl6.backend.response.MessageResponse;
import com.pbl6.backend.security.CustomUserDetailsService;
import com.pbl6.backend.service.MessageService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/messages")
public class MessageController {

    private final MessageService messageService;

    public MessageController(MessageService messageService) {
        this.messageService = messageService;
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

    // Gửi tin nhắn thường trong hội thoại đã tồn tại
    @PostMapping
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<MessageResponse> sendMessage(@RequestBody @jakarta.validation.Valid MessageSendRequest req) {
        var principal = getCurrentPrincipal();
        MessageResponse resp = messageService.sendMessage(principal.getUser(), req);
        return ResponseEntity.ok(resp);
    }

    // Gửi tin nhắn reply một post (kèm media của post)
    @PostMapping("/reply-post")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<MessageResponse> replyPost(@RequestBody @jakarta.validation.Valid ReplyPostMessageRequest req) {
        var principal = getCurrentPrincipal();
        MessageResponse resp = messageService.replyPost(principal.getUser(), req);
        return ResponseEntity.ok(resp);
    }
}
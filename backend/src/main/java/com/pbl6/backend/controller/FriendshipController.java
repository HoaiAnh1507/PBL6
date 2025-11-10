package com.pbl6.backend.controller;

import com.pbl6.backend.response.FriendshipResponse;
import com.pbl6.backend.response.PublicUserResponse;
import com.pbl6.backend.model.Friendship;
import com.pbl6.backend.security.CustomUserDetailsService;
import com.pbl6.backend.service.FriendshipService;
import com.pbl6.backend.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/friendships")
public class FriendshipController {

    @Autowired
    private FriendshipService friendshipService;

    @Autowired
    private UserService userService;

    // Helper: lấy principal hiện tại từ SecurityContext
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

    @PostMapping("/request/{targetUsername}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> sendFriendRequest(@PathVariable String targetUsername) {
        CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
        Friendship friendship = friendshipService.sendFriendRequest(principal.getUser().getUserId(), targetUsername);
        return ResponseEntity.ok(new FriendshipResponse(friendship));
    }

    @PostMapping("/accept/{senderUsername}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> acceptFriendRequest(@PathVariable String senderUsername) {
        CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
        Friendship friendship = friendshipService.acceptFriendRequest(principal.getUser().getUserId(), senderUsername);
        return ResponseEntity.ok(new FriendshipResponse(friendship));
    }

    @PostMapping("/reject/{senderUsername}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> rejectFriendRequest(@PathVariable String senderUsername) {
        CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
        friendshipService.rejectFriendRequest(principal.getUser().getUserId(), senderUsername);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/block/{targetUsername}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> blockUser(@PathVariable String targetUsername) {
        CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
        Friendship friendship = friendshipService.blockUser(principal.getUser().getUserId(), targetUsername);
        return ResponseEntity.ok(new FriendshipResponse(friendship));
    }

    @PostMapping("/unblock/{targetUsername}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> unblockUser(@PathVariable String targetUsername) {
        CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
        friendshipService.unblockUser(principal.getUser().getUserId(), targetUsername);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/unfriend/{targetUsername}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> unfriend(@PathVariable String targetUsername) {
        CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
        friendshipService.unfriend(principal.getUser().getUserId(), targetUsername);
        return ResponseEntity.ok().build();
    }

    // Hủy lời mời kết bạn do chính tôi đã gửi (người nhận chưa chấp nhận)
    @PostMapping("/cancel/{targetUsername}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> cancelSentFriendRequest(@PathVariable String targetUsername) {
        CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
        friendshipService.cancelSentFriendRequest(principal.getUser().getUserId(), targetUsername);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/requests")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> listRequests() {
        CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
        List<FriendshipResponse> incoming = friendshipService.getIncomingRequests(principal.getUser().getUserId())
                .stream().map(FriendshipResponse::new).collect(Collectors.toList());
        List<FriendshipResponse> sent = friendshipService.getSentRequests(principal.getUser().getUserId())
                .stream().map(FriendshipResponse::new).collect(Collectors.toList());
        Map<String, Object> payload = new HashMap<>();
        payload.put("incoming", incoming);
        payload.put("sent", sent);
        return ResponseEntity.ok(payload);
    }

    @GetMapping("")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> listFriends() {
        try {
            CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
            if (principal == null) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "Chưa xác thực");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
            }
            
            List<PublicUserResponse> friends = friendshipService.getFriends(principal.getUser().getUserId());
            return ResponseEntity.ok(friends);
        } catch (Exception e) {
            System.err.println("ERROR in listFriends controller: " + e.getMessage());
            e.printStackTrace();
            Map<String, String> error = new HashMap<>();
            error.put("error", "Đã xảy ra lỗi khi lấy danh sách bạn bè: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @GetMapping("/debug")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> debugFriends() {
        try {
            CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
            if (principal == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Not authenticated");
            }
            
            String userId = principal.getUser().getUserId();
            String username = principal.getUser().getUsername();
            
            Map<String, Object> debug = new HashMap<>();
            debug.put("currentUserId", userId);
            debug.put("currentUsername", username);
            debug.put("message", "Debug endpoint working");
            
            return ResponseEntity.ok(debug);
        } catch (Exception e) {
            System.err.println("ERROR in debug endpoint: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Debug error: " + e.getMessage());
        }
    }
}
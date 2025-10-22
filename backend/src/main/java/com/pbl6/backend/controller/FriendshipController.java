package com.pbl6.backend.controller;

import com.pbl6.backend.model.Friendship;
import com.pbl6.backend.request.CreateFriendshipRequest;
import com.pbl6.backend.response.FriendshipResponse;
import com.pbl6.backend.security.CustomUserDetailsService;
import com.pbl6.backend.service.FriendshipService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/friendships")
@CrossOrigin(origins = "*", maxAge = 3600)
public class FriendshipController {

    @Autowired
    private FriendshipService friendshipService;

    /**
     * Lấy thông tin người dùng hiện tại từ JWT token
     */
    private CustomUserDetailsService.CustomUserPrincipal getCurrentPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof CustomUserDetailsService.CustomUserPrincipal userPrincipal) {
            return userPrincipal;
        }
        return null;
    }

    /**
     * API gửi lời mời kết bạn
     * POST /api/friendships/request/{targetUsername}
     * 
     * Nhận vào username của người dùng được mời kết bạn từ path parameter
     * Backend sẽ tìm UUID từ username để lưu vào database
     * 
     * @param targetUsername Username của người dùng được mời kết bạn
     * @return ResponseEntity chứa thông tin mối quan hệ bạn bè đã tạo hoặc thông báo lỗi
     */
    @PostMapping("/request/{targetUsername}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> sendFriendRequest(@PathVariable String targetUsername) {
        try {
            // Lấy thông tin người dùng hiện tại từ JWT token
            CustomUserDetailsService.CustomUserPrincipal currentPrincipal = getCurrentPrincipal();
            if (currentPrincipal == null) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "Không thể xác thực người dùng");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
            }

            // Gửi lời mời kết bạn
            Friendship friendship = friendshipService.sendFriendRequest(
                    currentPrincipal.getUsername(), 
                    targetUsername
            );

            // Tạo response
            FriendshipResponse response = new FriendshipResponse(friendship);
            
            Map<String, Object> successResponse = new HashMap<>();
            successResponse.put("message", "Gửi lời mời kết bạn thành công");
            successResponse.put("friendship", response);
            
            return ResponseEntity.ok(successResponse);

        } catch (RuntimeException e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Đã xảy ra lỗi không mong muốn");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * API chấp nhận lời mời kết bạn
     * POST /api/friendships/accept/{senderUsername}
     * 
     * @param senderUsername Username của người gửi lời mời kết bạn
     * @return FriendshipResponse với trạng thái đã cập nhật
     */
    @PostMapping("/accept/{senderUsername}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> acceptFriendRequest(@PathVariable String senderUsername) {
        try {
            CustomUserDetailsService.CustomUserPrincipal currentPrincipal = getCurrentPrincipal();
            if (currentPrincipal == null) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "Không thể xác thực người dùng");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
            }

            Friendship friendship = friendshipService.acceptFriendRequest(currentPrincipal.getUsername(), senderUsername);
            
            FriendshipResponse response = new FriendshipResponse(friendship);
            
            Map<String, Object> successResponse = new HashMap<>();
            successResponse.put("message", "Chấp nhận lời mời kết bạn thành công");
            successResponse.put("friendship", response);
            
            return ResponseEntity.ok(successResponse);
            
        } catch (RuntimeException e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Đã xảy ra lỗi khi chấp nhận lời mời kết bạn");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * API từ chối lời mời kết bạn
     * POST /api/friendships/reject/{senderUsername}
     * 
     * @param senderUsername Username của người gửi lời mời kết bạn
     * @return Thông báo thành công
     */
    @PostMapping("/reject/{senderUsername}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> rejectFriendRequest(@PathVariable String senderUsername) {
        try {
            CustomUserDetailsService.CustomUserPrincipal currentPrincipal = getCurrentPrincipal();
            if (currentPrincipal == null) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "Không thể xác thực người dùng");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
            }

            friendshipService.rejectFriendRequest(currentPrincipal.getUsername(), senderUsername);
            
            Map<String, String> successResponse = new HashMap<>();
            successResponse.put("message", "Từ chối lời mời kết bạn thành công");
            
            return ResponseEntity.ok(successResponse);
            
        } catch (RuntimeException e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Đã xảy ra lỗi khi từ chối lời mời kết bạn");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * API chặn người dùng
     * POST /api/friendships/block/{targetUsername}
     * 
     * @param targetUsername Username của người dùng cần chặn
     * @return FriendshipResponse với trạng thái BLOCKED
     */
    @PostMapping("/block/{targetUsername}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> blockUser(@PathVariable String targetUsername) {
        try {
            CustomUserDetailsService.CustomUserPrincipal currentPrincipal = getCurrentPrincipal();
            if (currentPrincipal == null) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "Không thể xác thực người dùng");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
            }

            String currentUsername = currentPrincipal.getUsername();

            Friendship friendship = friendshipService.blockUser(currentUsername, targetUsername);
            
            FriendshipResponse response = new FriendshipResponse(friendship);
            
            Map<String, Object> result = new HashMap<>();
            result.put("message", "Chặn người dùng thành công");
            result.put("friendship", response);
            
            return ResponseEntity.ok(result);
            
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Đã xảy ra lỗi khi chặn người dùng");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }
}
package com.pbl6.backend.service;

import com.pbl6.backend.model.Friendship;
import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.FriendshipRepository;
import com.pbl6.backend.repository.UserRepository;
import com.pbl6.backend.response.PublicUserResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class FriendshipService {

    @Autowired
    private FriendshipRepository friendshipRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserService userService;

    /**
     * Gửi lời mời kết bạn giữa hai người dùng
     * @param currentUserId UUID của người dùng hiện tại (người gửi lời mời)
     * @param targetUsername Username của người dùng được mời kết bạn
     * @return Friendship object đã được tạo
     * @throws RuntimeException nếu có lỗi xảy ra
     */
    @Transactional
    public Friendship sendFriendRequest(String currentUserId, String targetUsername) {
        // Tìm người dùng hiện tại theo ID
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hiện tại"));

        // Tìm người dùng được mời theo username
        User targetUser = userRepository.findByUsername(targetUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng được mời kết bạn"));

        // Không thể kết bạn với chính mình
        if (currentUser.getUserId().equals(targetUser.getUserId())) {
            throw new RuntimeException("Không thể gửi lời mời kết bạn cho chính mình");
        }

        // Kiểm tra xem đã có mối quan hệ nào giữa hai người dùng chưa (hai chiều)
        Optional<Friendship> existingFriendship = friendshipRepository.findByUsers(currentUser, targetUser);
        if (existingFriendship.isPresent()) {
            Friendship friendship = existingFriendship.get();
            switch (friendship.getStatus()) {
                case PENDING:
                    // Trường hợp đã có lời mời
                    throw new RuntimeException("Đã tồn tại lời mời kết bạn giữa hai người dùng");
                case ACCEPTED:
                    throw new RuntimeException("Hai người dùng đã là bạn bè");
                case BLOCKED:
                    throw new RuntimeException("Không thể gửi lời mời kết bạn do đã bị chặn");
            }
        }

        // Tạo mối quan hệ bạn bè mới với trạng thái PENDING
        Friendship friendship = new Friendship();
        friendship.setUserOne(currentUser);  // Người gửi lời mời
        friendship.setUserTwo(targetUser);   // Người nhận lời mời
        friendship.setStatus(Friendship.FriendshipStatus.PENDING);
        friendship.setActionUser(currentUser); // người thực hiện hành động

        return friendshipRepository.save(friendship);
    }

    /**
     * Chấp nhận lời mời kết bạn
     * @param currentUserId UUID của người dùng hiện tại (người nhận lời mời)
     * @param senderUsername Username của người gửi lời mời kết bạn
     * @return Friendship object đã được cập nhật
     * @throws RuntimeException nếu có lỗi xảy ra
     */
    @Transactional
    public Friendship acceptFriendRequest(String currentUserId, String senderUsername) {
        // Tìm người dùng hiện tại theo ID
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hiện tại"));

        // Tìm người gửi lời mời theo username
        User senderUser = userRepository.findByUsername(senderUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người gửi lời mời"));

        // Tìm mối quan hệ bạn bè (hai chiều)
        Friendship friendship = friendshipRepository.findByUsers(senderUser, currentUser)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lời mời kết bạn"));

        // Kiểm tra trạng thái hiện tại
        if (friendship.getStatus() != Friendship.FriendshipStatus.PENDING) {
            throw new RuntimeException("Lời mời kết bạn không ở trạng thái chờ xử lý");
        }

        // Cập nhật trạng thái thành ACCEPTED
        friendship.setStatus(Friendship.FriendshipStatus.ACCEPTED);
        friendship.setActionUser(currentUser); // người thực hiện hành động
        return friendshipRepository.save(friendship);
    }

    /**
     * Từ chối lời mời kết bạn
     * @param currentUserId UUID của người dùng hiện tại (người nhận lời mời)
     * @param senderUsername Username của người gửi lời mời kết bạn
     * @throws RuntimeException nếu có lỗi xảy ra
     */
    @Transactional
    public void rejectFriendRequest(String currentUserId, String senderUsername) {
        // Tìm người dùng hiện tại theo ID
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hiện tại"));

        // Tìm người gửi lời mời theo username
        User senderUser = userRepository.findByUsername(senderUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người gửi lời mời"));

        // Tìm mối quan hệ bạn bè (hai chiều)
        Friendship friendship = friendshipRepository.findByUsers(senderUser, currentUser)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lời mời kết bạn"));

        // Kiểm tra trạng thái hiện tại
        if (friendship.getStatus() != Friendship.FriendshipStatus.PENDING) {
            throw new RuntimeException("Lời mời kết bạn không ở trạng thái chờ xử lý");
        }

        // Xóa mối quan hệ bạn bè (từ chối = xóa)
        friendshipRepository.delete(friendship);
    }

    /**
     * Chặn người dùng
     * @param currentUserId UUID của người dùng hiện tại
     * @param targetUsername Username của người dùng bị chặn
     * @return Friendship object với trạng thái BLOCKED
     */
    @Transactional
    public Friendship blockUser(String currentUserId, String targetUsername) {
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hiện tại"));
        User targetUser = userRepository.findByUsername(targetUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng cần chặn"));

        if (currentUser.getUserId().equals(targetUser.getUserId())) {
            throw new RuntimeException("Không thể chặn chính mình");
        }

        Optional<Friendship> existingFriendship = friendshipRepository.findByUsers(currentUser, targetUser);
        Friendship friendship = existingFriendship.orElseGet(() -> new Friendship(currentUser, targetUser));

        friendship.setStatus(Friendship.FriendshipStatus.BLOCKED);
        friendship.setActionUser(currentUser); // người thực hiện hành động
        return friendshipRepository.save(friendship);
    }

    /**
     * Bỏ chặn người dùng (xóa trạng thái BLOCKED)
     */
    @Transactional
    public void unblockUser(String currentUserId, String targetUsername) {
        User currentUser = userRepository.findById(currentUserId)
            .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hiện tại"));
        User targetUser = userRepository.findByUsername(targetUsername)
            .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng cần bỏ chặn"));

        Friendship friendship = friendshipRepository.findByUsers(currentUser, targetUser)
            .orElseThrow(() -> new RuntimeException("Không có trạng thái chặn giữa hai người dùng"));

        if (friendship.getStatus() != Friendship.FriendshipStatus.BLOCKED) {
            throw new RuntimeException("Quan hệ hiện tại không ở trạng thái chặn");
        }

        friendshipRepository.delete(friendship);
    }

    /**
     * Xóa bạn (hủy quan hệ ACCEPTED) - hai chiều
     */
    @Transactional
    public void unfriend(String currentUserId, String targetUsername) {
        User currentUser = userRepository.findById(currentUserId)
            .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hiện tại"));
        User targetUser = userRepository.findByUsername(targetUsername)
            .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng để xóa bạn"));

        Friendship friendship = friendshipRepository.findByUsers(currentUser, targetUser)
            .orElseThrow(() -> new RuntimeException("Không tồn tại quan hệ bạn bè"));

        if (friendship.getStatus() != Friendship.FriendshipStatus.ACCEPTED) {
            throw new RuntimeException("Chỉ có thể xóa bạn khi đang là bạn bè");
        }

        friendshipRepository.delete(friendship);
    }

    /**
     * Danh sách yêu cầu kết bạn đến tôi (incoming) và tôi đã gửi (sent)
     */
    @Transactional(readOnly = true)
    public List<Friendship> getIncomingRequests(String currentUserId) {
        User currentUser = userRepository.findById(currentUserId)
            .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hiện tại"));
        return friendshipRepository.findPendingRequestsForUser(currentUser);
    }

    @Transactional(readOnly = true)
    public List<Friendship> getSentRequests(String currentUserId) {
        User currentUser = userRepository.findById(currentUserId)
            .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hiện tại"));
        return friendshipRepository.findSentRequestsByUser(currentUser);
    }

    /**
     * Danh sách bạn bè của tôi - trả về DTO trong transaction để tránh LazyInitialization
     */
    @Transactional(readOnly = true)
    public List<PublicUserResponse> getFriends(String currentUserId) {
        try {
            System.out.println("DEBUG: getFriends called with userId: " + currentUserId);
            
            User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hiện tại"));
            
            System.out.println("DEBUG: Found current user: " + currentUser.getUsername());
            
            List<User> friends = friendshipRepository.findFriendsByUser(currentUser);
            System.out.println("DEBUG: Found " + friends.size() + " friends");
            
            List<PublicUserResponse> result = friends.stream()
                    .map(friend -> {
                        System.out.println("DEBUG: Mapping friend: " + friend.getUsername());
                        return userService.toPublicUserResponse(friend);
                    })
                    .collect(Collectors.toList());
            
            System.out.println("DEBUG: Successfully mapped " + result.size() + " friends to DTOs");
            return result;
            
        } catch (Exception e) {
            System.err.println("ERROR in getFriends: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Lỗi khi lấy danh sách bạn bè: " + e.getMessage(), e);
        }
    }
}
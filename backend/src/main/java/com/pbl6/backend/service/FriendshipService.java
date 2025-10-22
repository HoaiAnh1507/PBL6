package com.pbl6.backend.service;

import com.pbl6.backend.model.Friendship;
import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.FriendshipRepository;
import com.pbl6.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class FriendshipService {

    @Autowired
    private FriendshipRepository friendshipRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * Gửi lời mời kết bạn giữa hai người dùng
     * @param currentUsername Username của người dùng hiện tại (người gửi lời mời)
     * @param targetUsername Username của người dùng được mời kết bạn
     * @return Friendship object đã được tạo
     * @throws RuntimeException nếu có lỗi xảy ra
     */
    @Transactional
    public Friendship sendFriendRequest(String currentUsername, String targetUsername) {
        // Kiểm tra không thể kết bạn với chính mình
        if (currentUsername.equals(targetUsername)) {
            throw new RuntimeException("Không thể gửi lời mời kết bạn cho chính mình");
        }

        // Tìm người dùng hiện tại
        User currentUser = userRepository.findByUsername(currentUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hiện tại"));

        // Tìm người dùng được mời
        User targetUser = userRepository.findByUsername(targetUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng được mời kết bạn"));

        // Kiểm tra xem đã có mối quan hệ nào giữa hai người dùng chưa
        Optional<Friendship> existingFriendship = friendshipRepository.findByUsers(currentUser, targetUser);
        if (existingFriendship.isPresent()) {
            Friendship friendship = existingFriendship.get();
            switch (friendship.getStatus()) {
                case PENDING:
                    // Kiểm tra xem ai là người gửi lời mời trước đó
                    if (friendship.getUserOne().equals(currentUser)) {
                        throw new RuntimeException("Bạn đã gửi lời mời kết bạn cho người này rồi");
                    } else {
                        throw new RuntimeException("Người này đã gửi lời mời kết bạn cho bạn, hãy chấp nhận hoặc từ chối");
                    }
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

        return friendshipRepository.save(friendship);
    }

    /**
     * Chấp nhận lời mời kết bạn
     * @param currentUsername Username của người dùng hiện tại (người nhận lời mời)
     * @param senderUsername Username của người gửi lời mời kết bạn
     * @return Friendship object đã được cập nhật
     * @throws RuntimeException nếu có lỗi xảy ra
     */
    @Transactional
    public Friendship acceptFriendRequest(String currentUsername, String senderUsername) {
        // Tìm người dùng hiện tại
        User currentUser = userRepository.findByUsername(currentUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hiện tại"));

        // Tìm người gửi lời mời
        User senderUser = userRepository.findByUsername(senderUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người gửi lời mời"));

        // Tìm mối quan hệ bạn bè
        Friendship friendship = friendshipRepository.findByUsers(senderUser, currentUser)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lời mời kết bạn"));

        // Kiểm tra người dùng hiện tại có phải là người nhận lời mời không
        if (!friendship.getUserTwo().equals(currentUser)) {
            throw new RuntimeException("Bạn không có quyền chấp nhận lời mời này");
        }

        // Kiểm tra người gửi có đúng không
        if (!friendship.getUserOne().equals(senderUser)) {
            throw new RuntimeException("Lời mời không phải từ người dùng này");
        }

        // Kiểm tra trạng thái hiện tại
        if (friendship.getStatus() != Friendship.FriendshipStatus.PENDING) {
            throw new RuntimeException("Lời mời kết bạn không ở trạng thái chờ xử lý");
        }

        // Cập nhật trạng thái thành ACCEPTED
        friendship.setStatus(Friendship.FriendshipStatus.ACCEPTED);
        return friendshipRepository.save(friendship);
    }

    /**
     * Từ chối lời mời kết bạn
     * @param currentUsername Username của người dùng hiện tại (người nhận lời mời)
     * @param senderUsername Username của người gửi lời mời kết bạn
     * @throws RuntimeException nếu có lỗi xảy ra
     */
    @Transactional
    public void rejectFriendRequest(String currentUsername, String senderUsername) {
        // Tìm người dùng hiện tại
        User currentUser = userRepository.findByUsername(currentUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hiện tại"));

        // Tìm người gửi lời mời
        User senderUser = userRepository.findByUsername(senderUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người gửi lời mời"));

        // Tìm mối quan hệ bạn bè
        Friendship friendship = friendshipRepository.findByUsers(senderUser, currentUser)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lời mời kết bạn"));

        // Kiểm tra người dùng hiện tại có phải là người nhận lời mời không
        if (!friendship.getUserTwo().equals(currentUser)) {
            throw new RuntimeException("Bạn không có quyền từ chối lời mời này");
        }

        // Kiểm tra người gửi có đúng không
        if (!friendship.getUserOne().equals(senderUser)) {
            throw new RuntimeException("Lời mời không phải từ người dùng này");
        }

        // Kiểm tra trạng thái hiện tại
        if (friendship.getStatus() != Friendship.FriendshipStatus.PENDING) {
            throw new RuntimeException("Lời mời kết bạn không ở trạng thái chờ xử lý");
        }

        // Xóa mối quan hệ bạn bè (từ chối = xóa)
        friendshipRepository.delete(friendship);
    }

    /**
     * Chặn người dùng
     * @param currentUsername Username của người dùng hiện tại
     * @param targetUsername Username của người dùng bị chặn
     * @return Friendship object với trạng thái BLOCKED
     */
    @Transactional
    public Friendship blockUser(String currentUsername, String targetUsername) {
        if (currentUsername.equals(targetUsername)) {
            throw new RuntimeException("Không thể chặn chính mình");
        }

        User currentUser = userRepository.findByUsername(currentUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng hiện tại"));

        User targetUser = userRepository.findByUsername(targetUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng cần chặn"));

        // Tìm hoặc tạo mối quan hệ
        Optional<Friendship> existingFriendship = friendshipRepository.findByUsers(currentUser, targetUser);
        
        Friendship friendship;
        if (existingFriendship.isPresent()) {
            friendship = existingFriendship.get();
        } else {
            friendship = new Friendship(currentUser, targetUser);
        }

        friendship.setStatus(Friendship.FriendshipStatus.BLOCKED);
        return friendshipRepository.save(friendship);
    }
}
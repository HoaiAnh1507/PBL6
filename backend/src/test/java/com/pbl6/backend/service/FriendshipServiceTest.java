package com.pbl6.backend.service;

import com.pbl6.backend.model.Conversation;
import com.pbl6.backend.model.Friendship;
import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.ConversationRepository;
import com.pbl6.backend.repository.FriendshipRepository;
import com.pbl6.backend.repository.UserRepository;
import com.pbl6.backend.response.PublicUserResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit Test cho FriendshipService
 * Test các nghiệp vụ quản lý quan hệ bạn bè
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("Friendship Service Tests")
class FriendshipServiceTest {

    @Mock
    private FriendshipRepository friendshipRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserService userService;

    @Mock
    private ConversationRepository conversationRepository;

    @InjectMocks
    private FriendshipService friendshipService;

    private User user1;
    private User user2;
    private User user3;

    @BeforeEach
    void setUp() {
        // User 1 - Trần Đức Duy
        user1 = new User();
        user1.setUserId("user-1-id");
        user1.setUsername("tranducduy");
        user1.setEmail("tranducuduy739@gmail.com");
        user1.setFullName("Trần Đức Duy");
        user1.setAccountStatus(User.AccountStatus.ACTIVE);
        user1.setCreatedAt(LocalDateTime.now());

        // User 2 - Nguyễn Hoài Anh
        user2 = new User();
        user2.setUserId("user-2-id");
        user2.setUsername("nguyenhoaianh");
        user2.setEmail("hoaianh@example.com");
        user2.setFullName("Nguyễn Hoài Anh");
        user2.setAccountStatus(User.AccountStatus.ACTIVE);
        user2.setCreatedAt(LocalDateTime.now());

        // User 3 - Nguyễn Thành Hiếu
        user3 = new User();
        user3.setUserId("user-3-id");
        user3.setUsername("nguyenthanhhieu");
        user3.setEmail("thanhhieu@example.com");
        user3.setFullName("Nguyễn Thành Hiếu");
        user3.setAccountStatus(User.AccountStatus.ACTIVE);
        user3.setCreatedAt(LocalDateTime.now());
    }

    @Test
    @DisplayName("Send Friend Request - Success")
    void whenSendFriendRequest_thenSuccess() {
        // Arrange
        when(userRepository.findById(user1.getUserId())).thenReturn(Optional.of(user1));
        when(userRepository.findByUsername(user2.getUsername())).thenReturn(Optional.of(user2));
        when(friendshipRepository.findByUsers(user1, user2)).thenReturn(Optional.empty());

        Friendship savedFriendship = new Friendship();
        savedFriendship.setFriendshipId("friendship-123");
        savedFriendship.setUserOne(user1);
        savedFriendship.setUserTwo(user2);
        savedFriendship.setStatus(Friendship.FriendshipStatus.PENDING);
        savedFriendship.setActionUser(user1);

        when(friendshipRepository.save(any(Friendship.class))).thenReturn(savedFriendship);

        // Act
        Friendship result = friendshipService.sendFriendRequest(user1.getUserId(), user2.getUsername());

        // Assert
        assertThat(result).isNotNull();
        assertThat(result.getUserOne()).isEqualTo(user1);
        assertThat(result.getUserTwo()).isEqualTo(user2);
        assertThat(result.getStatus()).isEqualTo(Friendship.FriendshipStatus.PENDING);
        assertThat(result.getActionUser()).isEqualTo(user1);

        verify(userRepository, times(1)).findById(user1.getUserId());
        verify(userRepository, times(1)).findByUsername(user2.getUsername());
        verify(friendshipRepository, times(1)).save(any(Friendship.class));
    }

    @Test
    @DisplayName("Send Friend Request - Current User Not Found")
    void whenSendFriendRequestWithInvalidCurrentUser_thenThrowException() {
        // Arrange
        when(userRepository.findById("invalid-id")).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> friendshipService.sendFriendRequest("invalid-id", user2.getUsername()))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Không tìm thấy người dùng hiện tại");

        verify(userRepository, times(1)).findById("invalid-id");
        verify(friendshipRepository, never()).save(any());
    }

    @Test
    @DisplayName("Send Friend Request - Target User Not Found")
    void whenSendFriendRequestWithInvalidTargetUser_thenThrowException() {
        // Arrange
        when(userRepository.findById(user1.getUserId())).thenReturn(Optional.of(user1));
        when(userRepository.findByUsername("invaliduser")).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> friendshipService.sendFriendRequest(user1.getUserId(), "invaliduser"))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Không tìm thấy người dùng được mời kết bạn");

        verify(friendshipRepository, never()).save(any());
    }

    @Test
    @DisplayName("Send Friend Request to Self - Should Throw Exception")
    void whenSendFriendRequestToSelf_thenThrowException() {
        // Arrange
        when(userRepository.findById(user1.getUserId())).thenReturn(Optional.of(user1));
        when(userRepository.findByUsername(user1.getUsername())).thenReturn(Optional.of(user1));

        // Act & Assert
        assertThatThrownBy(() -> friendshipService.sendFriendRequest(user1.getUserId(), user1.getUsername()))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Không thể gửi lời mời kết bạn cho chính mình");

        verify(friendshipRepository, never()).save(any());
    }

    @Test
    @DisplayName("Send Friend Request - Already Pending")
    void whenSendFriendRequestAlreadyPending_thenThrowException() {
        // Arrange
        Friendship existingFriendship = new Friendship();
        existingFriendship.setUserOne(user1);
        existingFriendship.setUserTwo(user2);
        existingFriendship.setStatus(Friendship.FriendshipStatus.PENDING);

        when(userRepository.findById(user1.getUserId())).thenReturn(Optional.of(user1));
        when(userRepository.findByUsername(user2.getUsername())).thenReturn(Optional.of(user2));
        when(friendshipRepository.findByUsers(user1, user2)).thenReturn(Optional.of(existingFriendship));

        // Act & Assert
        assertThatThrownBy(() -> friendshipService.sendFriendRequest(user1.getUserId(), user2.getUsername()))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Đã tồn tại lời mời kết bạn");

        verify(friendshipRepository, never()).save(any());
    }

    @Test
    @DisplayName("Send Friend Request - Already Friends")
    void whenSendFriendRequestAlreadyAccepted_thenThrowException() {
        // Arrange
        Friendship existingFriendship = new Friendship();
        existingFriendship.setUserOne(user1);
        existingFriendship.setUserTwo(user2);
        existingFriendship.setStatus(Friendship.FriendshipStatus.ACCEPTED);

        when(userRepository.findById(user1.getUserId())).thenReturn(Optional.of(user1));
        when(userRepository.findByUsername(user2.getUsername())).thenReturn(Optional.of(user2));
        when(friendshipRepository.findByUsers(user1, user2)).thenReturn(Optional.of(existingFriendship));

        // Act & Assert
        assertThatThrownBy(() -> friendshipService.sendFriendRequest(user1.getUserId(), user2.getUsername()))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Hai người dùng đã là bạn bè");

        verify(friendshipRepository, never()).save(any());
    }

    @Test
    @DisplayName("Send Friend Request - User Blocked")
    void whenSendFriendRequestToBlockedUser_thenThrowException() {
        // Arrange
        Friendship existingFriendship = new Friendship();
        existingFriendship.setUserOne(user1);
        existingFriendship.setUserTwo(user2);
        existingFriendship.setStatus(Friendship.FriendshipStatus.BLOCKED);

        when(userRepository.findById(user1.getUserId())).thenReturn(Optional.of(user1));
        when(userRepository.findByUsername(user2.getUsername())).thenReturn(Optional.of(user2));
        when(friendshipRepository.findByUsers(user1, user2)).thenReturn(Optional.of(existingFriendship));

        // Act & Assert
        assertThatThrownBy(() -> friendshipService.sendFriendRequest(user1.getUserId(), user2.getUsername()))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Không thể gửi lời mời kết bạn do đã bị chặn");

        verify(friendshipRepository, never()).save(any());
    }

    @Test
    @DisplayName("Get Friends - Success")
    void whenGetFriends_thenReturnFriendsList() {
        // Arrange
        List<User> friends = Arrays.asList(user2, user3);

        PublicUserResponse response2 = new PublicUserResponse();
        response2.setUserId(user2.getUserId());
        response2.setUsername(user2.getUsername());
        response2.setFullName(user2.getFullName());

        PublicUserResponse response3 = new PublicUserResponse();
        response3.setUserId(user3.getUserId());
        response3.setUsername(user3.getUsername());
        response3.setFullName(user3.getFullName());

        when(userRepository.findById(user1.getUserId())).thenReturn(Optional.of(user1));
        when(friendshipRepository.findFriendsByUser(user1)).thenReturn(friends);
        when(userService.toPublicUserResponse(user2)).thenReturn(response2);
        when(userService.toPublicUserResponse(user3)).thenReturn(response3);

        // Act
        List<PublicUserResponse> result = friendshipService.getFriends(user1.getUserId());

        // Assert
        assertThat(result).hasSize(2);
        assertThat(result.get(0).getUsername()).isEqualTo("nguyenhoaianh");
        assertThat(result.get(1).getUsername()).isEqualTo("nguyenthanhhieu");

        verify(userRepository, times(1)).findById(user1.getUserId());
        verify(friendshipRepository, times(1)).findFriendsByUser(user1);
    }

    @Test
    @DisplayName("Get Friends - User Not Found")
    void whenGetFriendsForInvalidUser_thenThrowException() {
        // Arrange
        when(userRepository.findById("invalid-id")).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> friendshipService.getFriends("invalid-id"))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Không tìm thấy người dùng hiện tại");
    }

    @Test
    @DisplayName("Get Friends - Empty List")
    void whenUserHasNoFriends_thenReturnEmptyList() {
        // Arrange
        when(userRepository.findById(user1.getUserId())).thenReturn(Optional.of(user1));
        when(friendshipRepository.findFriendsByUser(user1)).thenReturn(Collections.emptyList());

        // Act
        List<PublicUserResponse> result = friendshipService.getFriends(user1.getUserId());

        // Assert
        assertThat(result).isEmpty();

        verify(friendshipRepository, times(1)).findFriendsByUser(user1);
    }
}

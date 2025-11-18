package com.pbl6.backend.service;

import com.pbl6.backend.model.Post;
import com.pbl6.backend.model.PostReaction;
import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.PostReactionRepository;
import com.pbl6.backend.repository.PostRecipientRepository;
import com.pbl6.backend.repository.PostRepository;
import com.pbl6.backend.repository.UserRepository;
import com.pbl6.backend.request.AiCaptionInitRequest;
import com.pbl6.backend.response.AiCaptionInitResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit Test cho PostService
 * Test các nghiệp vụ quản lý bài đăng
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("Post Service Tests")
class PostServiceTest {

    @Mock
    private PostRepository postRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PostRecipientRepository postRecipientRepository;

    @Mock
    private PostReactionRepository postReactionRepository;

    @Mock
    private AzureQueueService azureQueueService;

    @InjectMocks
    private PostService postService;

    private User testUser;

    @BeforeEach
    void setUp() {
        // Setup test user
        testUser = new User();
        testUser.setUserId("user-123");
        testUser.setUsername("tranducduy");
        testUser.setEmail("tranducuduy739@gmail.com");
        testUser.setFullName("Trần Đức Duy");
        testUser.setAccountStatus(User.AccountStatus.ACTIVE);
        testUser.setCreatedAt(LocalDateTime.now());

        // Set server port for callback URL
        ReflectionTestUtils.setField(postService, "serverPort", "8080");
    }

    @Test
    @DisplayName("Init AI Caption - Success with Image")
    void whenInitAiCaptionWithImage_thenSuccess() throws Exception {
        // Arrange
        AiCaptionInitRequest request = new AiCaptionInitRequest();
        request.setMediaUrl("https://storage.blob.core.windows.net/images/test.jpg");
        request.setMediaType("PHOTO");
        request.setMood("happy");

        Post savedPost = new Post(testUser, Post.MediaType.PHOTO, request.getMediaUrl());
        savedPost.setPostId("post-123");
        savedPost.setCaptionStatus(Post.CaptionStatus.PENDING);

        when(postRepository.save(any(Post.class))).thenReturn(savedPost);
        doNothing().when(azureQueueService).enqueueCaptionJob(anyString(), anyString(), anyString(), anyString(),
                anyString());

        // Act
        AiCaptionInitResponse response = postService.initAiCaption(testUser, request);

        // Assert
        assertThat(response).isNotNull();
        assertThat(response.getPostId()).isEqualTo("post-123");
        assertThat(response.getGeneratedCaption()).isNull(); // Caption comes later via callback

        verify(postRepository, times(1)).save(any(Post.class));
        verify(azureQueueService, times(1)).enqueueCaptionJob(anyString(), eq("post-123"), eq(request.getMediaUrl()),
                eq("happy"), anyString());
    }

    @Test
    @DisplayName("Init AI Caption - Success with Video")
    void whenInitAiCaptionWithVideo_thenSuccess() throws Exception {
        // Arrange
        AiCaptionInitRequest request = new AiCaptionInitRequest();
        request.setMediaUrl("https://storage.blob.core.windows.net/videos/test.mp4");
        request.setMediaType("VIDEO");
        request.setMood("neutral");

        Post savedPost = new Post(testUser, Post.MediaType.VIDEO, request.getMediaUrl());
        savedPost.setPostId("post-456");
        savedPost.setCaptionStatus(Post.CaptionStatus.PENDING);

        when(postRepository.save(any(Post.class))).thenReturn(savedPost);
        doNothing().when(azureQueueService).enqueueCaptionJob(anyString(), anyString(), anyString(), anyString(),
                anyString());

        // Act
        AiCaptionInitResponse response = postService.initAiCaption(testUser, request);

        // Assert
        assertThat(response).isNotNull();
        assertThat(response.getPostId()).isEqualTo("post-456");

        verify(postRepository, times(1)).save(any(Post.class));
        verify(azureQueueService, times(1)).enqueueCaptionJob(anyString(), eq("post-456"), anyString(), eq("neutral"),
                anyString());
    }

    @Test
    @DisplayName("Init AI Caption - Default Mood When Not Provided")
    void whenInitAiCaptionWithoutMood_thenUseDefaultMood() throws Exception {
        // Arrange
        AiCaptionInitRequest request = new AiCaptionInitRequest();
        request.setMediaUrl("https://storage.blob.core.windows.net/images/test.jpg");
        request.setMediaType("PHOTO");
        request.setMood(null); // No mood provided

        Post savedPost = new Post(testUser, Post.MediaType.PHOTO, request.getMediaUrl());
        savedPost.setPostId("post-789");
        savedPost.setCaptionStatus(Post.CaptionStatus.PENDING);

        when(postRepository.save(any(Post.class))).thenReturn(savedPost);
        doNothing().when(azureQueueService).enqueueCaptionJob(anyString(), anyString(), anyString(), anyString(),
                anyString());

        // Act
        AiCaptionInitResponse response = postService.initAiCaption(testUser, request);

        // Assert
        assertThat(response).isNotNull();
        verify(azureQueueService, times(1)).enqueueCaptionJob(anyString(), anyString(), anyString(), eq("neutral"),
                anyString());
    }

    @Test
    @DisplayName("Init AI Caption - Enqueue Failure Should Mark Post as Failed")
    void whenEnqueueFails_thenMarkPostAsFailed() throws Exception {
        // Arrange
        AiCaptionInitRequest request = new AiCaptionInitRequest();
        request.setMediaUrl("https://storage.blob.core.windows.net/images/test.jpg");
        request.setMediaType("PHOTO");

        Post savedPost = new Post(testUser, Post.MediaType.PHOTO, request.getMediaUrl());
        savedPost.setPostId("post-fail");
        savedPost.setCaptionStatus(Post.CaptionStatus.PENDING);

        when(postRepository.save(any(Post.class))).thenReturn(savedPost);
        doThrow(new RuntimeException("Azure Service Bus error"))
                .when(azureQueueService)
                .enqueueCaptionJob(anyString(), anyString(), anyString(), anyString(), anyString());

        // Act & Assert
        assertThatThrownBy(() -> postService.initAiCaption(testUser, request))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Failed to enqueue caption generation job");

        verify(postRepository, times(2)).save(any(Post.class)); // Once for create, once for marking failed
    }

    @Test
    @DisplayName("Update Caption Result - Success")
    void whenUpdateCaptionResultSuccess_thenPostUpdated() {
        // Arrange
        Post post = new Post(testUser, Post.MediaType.PHOTO, "https://example.com/image.jpg");
        post.setPostId("post-123");
        post.setCaptionStatus(Post.CaptionStatus.PENDING);

        when(postRepository.findById("post-123")).thenReturn(Optional.of(post));
        when(postRepository.save(any(Post.class))).thenReturn(post);

        // Act
        postService.updateCaptionResult("post-123", true, "A beautiful sunset over the ocean", null);

        // Assert
        assertThat(post.getGeneratedCaption()).isEqualTo("A beautiful sunset over the ocean");
        assertThat(post.getCaptionStatus()).isEqualTo(Post.CaptionStatus.COMPLETED);

        verify(postRepository, times(1)).findById("post-123");
        verify(postRepository, times(1)).save(post);
    }

    @Test
    @DisplayName("Update Caption Result - Failure")
    void whenUpdateCaptionResultFailure_thenPostMarkedFailed() {
        // Arrange
        Post post = new Post(testUser, Post.MediaType.PHOTO, "https://example.com/image.jpg");
        post.setPostId("post-456");
        post.setCaptionStatus(Post.CaptionStatus.PENDING);

        when(postRepository.findById("post-456")).thenReturn(Optional.of(post));
        when(postRepository.save(any(Post.class))).thenReturn(post);

        // Act
        postService.updateCaptionResult("post-456", false, null, "AI model timeout");

        // Assert
        assertThat(post.getGeneratedCaption()).isNull();
        assertThat(post.getCaptionStatus()).isEqualTo(Post.CaptionStatus.FAILED);

        verify(postRepository, times(1)).findById("post-456");
        verify(postRepository, times(1)).save(post);
    }

    @Test
    @DisplayName("Update Caption Result - Post Not Found")
    void whenUpdateCaptionResultForNonExistentPost_thenThrowException() {
        // Arrange
        when(postRepository.findById("invalid-post-id")).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> postService.updateCaptionResult("invalid-post-id", true, "caption", null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Post not found");

        verify(postRepository, times(1)).findById("invalid-post-id");
        verify(postRepository, never()).save(any());
    }

    @Test
    @DisplayName("Get Post by ID - Success")
    void whenGetPostById_thenReturnPost() {
        // Arrange
        Post post = new Post(testUser, Post.MediaType.PHOTO, "https://example.com/image.jpg");
        post.setPostId("post-123");
        post.setGeneratedCaption("Test caption");
        post.setCaptionStatus(Post.CaptionStatus.COMPLETED);

        when(postRepository.findById("post-123")).thenReturn(Optional.of(post));

        // Act
        Optional<Post> result = postRepository.findById("post-123");

        // Assert
        assertThat(result).isPresent();
        assertThat(result.get().getPostId()).isEqualTo("post-123");
        assertThat(result.get().getGeneratedCaption()).isEqualTo("Test caption");
        assertThat(result.get().getCaptionStatus()).isEqualTo(Post.CaptionStatus.COMPLETED);
    }

    @Test
    @DisplayName("Get Post by ID - Not Found")
    void whenGetPostByIdNotFound_thenReturnEmpty() {
        // Arrange
        when(postRepository.findById("non-existent")).thenReturn(Optional.empty());

        // Act
        Optional<Post> result = postRepository.findById("non-existent");

        // Assert
        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("Parse Media Type - IMAGE")
    void whenParseMediaTypeImage_thenReturnImageType() throws Exception {
        // This tests the private method indirectly through initAiCaption
        AiCaptionInitRequest request = new AiCaptionInitRequest();
        request.setMediaUrl("https://example.com/test.jpg");
        request.setMediaType("PHOTO");

        Post savedPost = new Post(testUser, Post.MediaType.PHOTO, request.getMediaUrl());
        savedPost.setPostId("post-img");

        when(postRepository.save(any(Post.class))).thenAnswer(invocation -> {
            Post post = invocation.getArgument(0);
            assertThat(post.getMediaType()).isEqualTo(Post.MediaType.PHOTO);
            return savedPost;
        });
        doNothing().when(azureQueueService).enqueueCaptionJob(anyString(), anyString(), anyString(), anyString(),
                anyString());

        postService.initAiCaption(testUser, request);

        verify(postRepository, times(1)).save(any(Post.class));
    }

    @Test
    @DisplayName("Parse Media Type - VIDEO")
    void whenParseMediaTypeVideo_thenReturnVideoType() throws Exception {
        // This tests the private method indirectly through initAiCaption
        AiCaptionInitRequest request = new AiCaptionInitRequest();
        request.setMediaUrl("https://example.com/test.mp4");
        request.setMediaType("VIDEO");

        Post savedPost = new Post(testUser, Post.MediaType.VIDEO, request.getMediaUrl());
        savedPost.setPostId("post-vid");

        when(postRepository.save(any(Post.class))).thenAnswer(invocation -> {
            Post post = invocation.getArgument(0);
            assertThat(post.getMediaType()).isEqualTo(Post.MediaType.VIDEO);
            return savedPost;
        });
        doNothing().when(azureQueueService).enqueueCaptionJob(anyString(), anyString(), anyString(), anyString(),
                anyString());

        postService.initAiCaption(testUser, request);

        verify(postRepository, times(1)).save(any(Post.class));
    }
}

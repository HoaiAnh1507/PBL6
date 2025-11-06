package com.pbl6.backend.service;

import com.pbl6.backend.model.Post;
import com.pbl6.backend.repository.PostRepository;
import com.pbl6.backend.response.CaptionJobResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class CaptionJobService {
    private final PostRepository postRepository;
    private final AiCaptionClient aiCaptionClient;

    // In-memory job states cho demo (có thể chuyển sang DB/Redis nếu cần)
    private final Map<String, CaptionJobResponse> jobs = new ConcurrentHashMap<>();

    @Value("${ai.caption.callback-path}")
    private String callbackPath;

    public CaptionJobService(PostRepository postRepository, AiCaptionClient aiCaptionClient) {
        this.postRepository = postRepository;
        this.aiCaptionClient = aiCaptionClient;
    }

    public Optional<CaptionJobResponse> getJob(String jobId) {
        return Optional.ofNullable(jobs.get(jobId));
    }

    @Transactional
    public CaptionJobResponse startJob(String postId, String language, String callbackUrl) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Post not found: " + postId));
        if (post.getMediaType() != Post.MediaType.VIDEO) {
            throw new IllegalStateException("Caption chỉ hỗ trợ post dạng VIDEO");
        }
        String videoUrl = post.getMediaUrl();
        if (videoUrl == null || videoUrl.isBlank()) {
            throw new IllegalStateException("Post không có mediaUrl để AI tải video");
        }

        // Đặt trạng thái về PENDING
        post.setCaptionStatus(Post.CaptionStatus.PENDING);
        post.setGeneratedCaption(null);
        postRepository.save(post);

        String jobId = UUID.randomUUID().toString();
        CaptionJobResponse job = new CaptionJobResponse(jobId, "PENDING");
        jobs.put(jobId, job);

        // Gọi AI server chạy async (không chặn)
        aiCaptionClient.startAsyncJob(jobId, postId, videoUrl, callbackUrl, language);

        return job;
    }

    @Transactional
    public void markCompleted(String jobId, String postId, String caption) {
        CaptionJobResponse state = jobs.getOrDefault(jobId, new CaptionJobResponse(jobId, "PENDING"));
        state.setStatus("COMPLETED");
        state.setCaption(caption);
        state.setError(null);
        jobs.put(jobId, state);

        // Cập nhật Post
        postRepository.findById(postId).ifPresent(post -> {
            post.setGeneratedCaption(caption);
            post.setCaptionStatus(Post.CaptionStatus.COMPLETED);
            postRepository.save(post);
        });
    }

    @Transactional
    public void markFailed(String jobId, String postId, String error) {
        CaptionJobResponse state = jobs.getOrDefault(jobId, new CaptionJobResponse(jobId, "PENDING"));
        state.setStatus("FAILED");
        state.setCaption(null);
        state.setError(error);
        jobs.put(jobId, state);

        // Cập nhật Post
        postRepository.findById(postId).ifPresent(post -> {
            post.setCaptionStatus(Post.CaptionStatus.FAILED);
            postRepository.save(post);
        });
    }
}
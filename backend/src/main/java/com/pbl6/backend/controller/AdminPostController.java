package com.pbl6.backend.controller;

import com.pbl6.backend.model.Post;
import com.pbl6.backend.repository.PostRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/posts")
@CrossOrigin(origins = "*")
public class AdminPostController {

    @Autowired
    private PostRepository postRepository;

    @GetMapping
    public ResponseEntity<?> getAllPosts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String mediaType,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String search) {
        
        Pageable pageable = PageRequest.of(page, size);
        Page<Post> posts;

        // Search by user info or caption
        if (search != null && !search.isEmpty()) {
            List<Post> allPosts = postRepository.findAll();
            List<Post> searchResults = allPosts.stream()
                .filter(p -> {
                    String searchLower = search.toLowerCase();
                    boolean matchUser = p.getUser() != null && (
                        (p.getUser().getFullName() != null && p.getUser().getFullName().toLowerCase().contains(searchLower)) ||
                        (p.getUser().getUsername() != null && p.getUser().getUsername().toLowerCase().contains(searchLower))
                    );
                    boolean matchCaption = (p.getFinalCaption() != null && p.getFinalCaption().toLowerCase().contains(searchLower)) ||
                                          (p.getGeneratedCaption() != null && p.getGeneratedCaption().toLowerCase().contains(searchLower));
                    return matchUser || matchCaption;
                })
                .collect(Collectors.toList());
            
            int start = (int) pageable.getOffset();
            int end = Math.min((start + pageable.getPageSize()), searchResults.size());
            List<Post> pageContent = searchResults.subList(start, end);
            posts = new org.springframework.data.domain.PageImpl<>(pageContent, pageable, searchResults.size());
        }
        // Filter by mediaType and/or status
        else if ((mediaType != null && !mediaType.isEmpty() && !"ALL".equalsIgnoreCase(mediaType)) ||
                 (status != null && !status.isEmpty() && !"ALL".equalsIgnoreCase(status))) {
            List<Post> filteredPosts = postRepository.findAll();
            
            // Filter by media type
            if (mediaType != null && !mediaType.isEmpty() && !"ALL".equalsIgnoreCase(mediaType)) {
                try {
                    Post.MediaType type = Post.MediaType.valueOf(mediaType.toUpperCase());
                    filteredPosts = filteredPosts.stream()
                        .filter(p -> p.getMediaType() == type)
                        .collect(Collectors.toList());
                } catch (IllegalArgumentException e) {
                    // Invalid type, ignore filter
                }
            }
            
            // Filter by caption status
            if (status != null && !status.isEmpty() && !"ALL".equalsIgnoreCase(status)) {
                try {
                    Post.CaptionStatus captionStatus = Post.CaptionStatus.valueOf(status.toUpperCase());
                    filteredPosts = filteredPosts.stream()
                        .filter(p -> p.getCaptionStatus() == captionStatus)
                        .collect(Collectors.toList());
                } catch (IllegalArgumentException e) {
                    // Invalid status, ignore filter
                }
            }
            
            int start = (int) pageable.getOffset();
            int end = Math.min((start + pageable.getPageSize()), filteredPosts.size());
            List<Post> pageContent = filteredPosts.subList(start, end);
            posts = new org.springframework.data.domain.PageImpl<>(pageContent, pageable, filteredPosts.size());
        }
        // Get all posts
        else {
            posts = postRepository.findAll(pageable);
        }

        return ResponseEntity.ok(posts);
    }

    @GetMapping("/{postId}")
    public ResponseEntity<?> getPostById(@PathVariable String postId) {
        return postRepository.findById(postId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/stats")
    public ResponseEntity<?> getPostStats() {
        long totalPosts = postRepository.count();
        long photoPosts = postRepository.countByMediaType(Post.MediaType.PHOTO);
        long videoPosts = postRepository.countByMediaType(Post.MediaType.VIDEO);
        long pendingPosts = postRepository.countByCaptionStatus(Post.CaptionStatus.PENDING);
        long completedPosts = postRepository.countByCaptionStatus(Post.CaptionStatus.COMPLETED);
        long failedPosts = postRepository.countByCaptionStatus(Post.CaptionStatus.FAILED);

        return ResponseEntity.ok(new java.util.HashMap<String, Object>() {{
            put("totalPosts", totalPosts);
            put("photoPosts", photoPosts);
            put("videoPosts", videoPosts);
            put("pendingPosts", pendingPosts);
            put("completedPosts", completedPosts);
            put("failedPosts", failedPosts);
        }});
    }
}

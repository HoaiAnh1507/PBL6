package com.pbl6.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Service
public class AiCaptionClient {
    @Value("${ai.caption.base-url}")
    private String aiBaseUrl;

    // Gửi yêu cầu khởi tạo job tới AI server
    public void startAsyncJob(String jobId, String postId, String videoUrl, String callbackUrl, String language) {
        String url = aiBaseUrl + "/v1/captions/async";

        Map<String, Object> body = new HashMap<>();
        body.put("job_id", jobId);
        body.put("post_id", postId);
        body.put("video_url", videoUrl);
        body.put("callback_url", callbackUrl);
        if (language != null && !language.isBlank()) {
            body.put("language", language);
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        RestTemplate restTemplate = new RestTemplate();
        restTemplate.postForEntity(url, new HttpEntity<>(body, headers), String.class);
    }
}
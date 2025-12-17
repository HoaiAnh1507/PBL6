package com.pbl6.backend.controller;

import com.pbl6.backend.response.MetricsOverviewResponse;
import com.pbl6.backend.service.MetricsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/metrics")
@CrossOrigin(origins = "*")
public class MetricsController {

    @Autowired
    private MetricsService metricsService;

    @GetMapping("/overview")
    public ResponseEntity<?> getOverview() {
        MetricsOverviewResponse response = metricsService.getOverview();
        return ResponseEntity.ok(response);
    }

    @GetMapping("/users")
    public ResponseEntity<?> getUserMetrics(
            @RequestParam(defaultValue = "7d") String period) {
        
        List<Map<String, Object>> metrics = metricsService.getUserMetrics(period);
        return ResponseEntity.ok(metrics);
    }

    @GetMapping("/posts")
    public ResponseEntity<?> getPostMetrics(
            @RequestParam(defaultValue = "7d") String period) {
        
        List<Map<String, Object>> metrics = metricsService.getPostMetrics(period);
        return ResponseEntity.ok(metrics);
    }
}

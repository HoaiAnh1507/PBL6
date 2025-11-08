package com.pbl6.backend.controller;

import com.pbl6.backend.request.SasTokenRequest;
import com.pbl6.backend.response.SasTokenResponse;
import com.pbl6.backend.service.StorageService;
import com.pbl6.backend.security.CustomUserDetailsService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/storage")
public class StorageController {

    private final StorageService storageService;

    public StorageController(StorageService storageService) {
        this.storageService = storageService;
    }

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

    // Generate short-lived read SAS for a blob
    @PostMapping("/sas")
    @PreAuthorize("hasAnyRole('USER','ADMIN')")
    public ResponseEntity<SasTokenResponse> generateSas(@RequestBody SasTokenRequest req) {
        int ttl = (req.getExpiresInSeconds() == null || req.getExpiresInSeconds() <= 0) ? 300 : req.getExpiresInSeconds();

        String access = req.getAccess();
        Map<String, Object> sas;
        if (access != null && access.equalsIgnoreCase("upload")) {
            String providedBlobName = req.getBlobName();
            String finalBlobName = providedBlobName;
            if (finalBlobName == null || finalBlobName.isBlank()) {
                // Auto-generate blob name: {userId}/{MM}/{timestamp}.jpg
                var principal = getCurrentPrincipal();
                String userId = principal.getUser().getUserId();
                int month = java.time.OffsetDateTime.now().getMonthValue();
                String monthStr = String.format("%02d", month);
                String timestamp = String.valueOf(System.currentTimeMillis());
                finalBlobName = userId + "/" + monthStr + "/" + timestamp + ".jpg";
            }
            sas = storageService.generateBlobUploadSas(req.getContainerName(), finalBlobName, ttl);
        } else {
            sas = storageService.generateBlobReadSas(req.getContainerName(), req.getBlobName(), ttl);
        }
        SasTokenResponse resp = new SasTokenResponse(
                (String) sas.get("sasToken"),
                (String) sas.get("signedUrl"),
                (String) sas.get("expiresOn")
        );
        return ResponseEntity.ok(resp);
    }
}
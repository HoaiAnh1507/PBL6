package com.pbl6.backend.security;

import org.springframework.stereotype.Service;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class TokenBlacklistService {
    private final Set<String> blacklist = ConcurrentHashMap.newKeySet();

    public void blacklist(String token) {
        if (token != null && !token.isBlank()) {
            blacklist.add(token);
        }
    }

    public boolean isBlacklisted(String token) {
        return token != null && blacklist.contains(token);
    }
}
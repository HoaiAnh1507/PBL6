package com.pbl6.backend.security;

import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Service
public class CustomUserDetailsService implements UserDetailsService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Override
    public UserDetails loadUserByUsername(String identifier) throws UsernameNotFoundException {
        Optional<User> userOptional;
        
        // Kiểm tra xem identifier có phải email không
        if (identifier.matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")) {
            userOptional = userRepository.findByEmail(identifier);
            if (userOptional.isEmpty()) {
                throw new UsernameNotFoundException("Không tìm thấy tài khoản với email: " + identifier);
            }
        } else if (identifier.matches("^[+]?[0-9]{10,15}$")) {
            // Kiểm tra xem có phải số điện thoại không (10-15 chữ số, có thể có dấu +)
            userOptional = userRepository.findByPhoneNumber(identifier);
            if (userOptional.isEmpty()) {
                throw new UsernameNotFoundException("Không tìm thấy tài khoản với số điện thoại: " + identifier);
            }
        } else {
            throw new UsernameNotFoundException("Vui lòng đăng nhập bằng email hoặc số điện thoại hợp lệ");
        }
        
        // Trả về principal với "username" chính là login identifier (email/phone)
        return new CustomUserPrincipal(userOptional.get(), identifier);
    }
    public static class CustomUserPrincipal implements UserDetails {
        private User user;
        private String principalIdentifier; // email hoặc số điện thoại được dùng để đăng nhập/token
        
        public CustomUserPrincipal(User user, String principalIdentifier) {
            this.user = user;
            this.principalIdentifier = principalIdentifier;
        }
        
        @Override
        public Collection<? extends GrantedAuthority> getAuthorities() {
            List<GrantedAuthority> authorities = new ArrayList<>();
            authorities.add(new SimpleGrantedAuthority("ROLE_USER"));
            return authorities;
        }
        
        @Override
        public String getPassword() {
            return user.getPasswordHash();
        }
        
        @Override
        public String getUsername() {
            // Trả về cùng giá trị với JWT subject (email hoặc số điện thoại)
            return principalIdentifier;
        }
        
        @Override
        public boolean isAccountNonExpired() {
            return true;
        }
        
        @Override
        public boolean isAccountNonLocked() {
            return user.getAccountStatus() != User.AccountStatus.SUSPENDED;
        }
        
        @Override
        public boolean isCredentialsNonExpired() {
            return true;
        }
        
        @Override
        public boolean isEnabled() {
            return user.getAccountStatus() == User.AccountStatus.ACTIVE;
        }
        
        public User getUser() {
            return user;
        }
    }
}
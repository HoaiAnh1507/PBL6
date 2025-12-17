package com.pbl6.backend.security;

import com.pbl6.backend.model.Admin;
import com.pbl6.backend.repository.AdminRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Optional;

@Service
public class AdminDetailsService {

    @Autowired
    private AdminRepository adminRepository;

    public UserDetails loadAdminByAdminId(String adminId) throws UsernameNotFoundException {
        Optional<Admin> adminOpt = adminRepository.findById(adminId);
        
        if (adminOpt.isEmpty()) {
            throw new UsernameNotFoundException("Admin not found with id: " + adminId);
        }
        
        Admin admin = adminOpt.get();
        
        Collection<GrantedAuthority> authorities = new ArrayList<>();
        authorities.add(new SimpleGrantedAuthority("ROLE_ADMIN"));
        
        return new User(admin.getAdminId(), admin.getPasswordHash(), authorities);
    }
}

package com.pbl6.backend.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    @Value("${spring.mail.from:}")
    private String fromAddress;

    @Value("${app.mail.from-name:LocketAI}")
    private String fromName;

    public void sendOtpEmail(String to, String otp) throws MessagingException {
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

        String subject = "Mã xác thực (OTP)";
        String html = "<div style='font-family:Arial,sans-serif'>" +
                "<h3>Mã OTP của bạn</h3>" +
                "<p>Mã OTP: <b>" + otp + "</b></p>" +
                "<p>Mã có hiệu lực trong 5 phút. Nếu bạn không yêu cầu, vui lòng bỏ qua email này.</p>" +
                "</div>";

        helper.setSubject(subject);
        helper.setTo(to);
        if (fromAddress != null && !fromAddress.isBlank()) {
            try {
                helper.setFrom(fromAddress, fromName);
            } catch (Exception e) {
                helper.setFrom(fromAddress);
            }
        }
        helper.setText(html, true);

        mailSender.send(message);
    }
}
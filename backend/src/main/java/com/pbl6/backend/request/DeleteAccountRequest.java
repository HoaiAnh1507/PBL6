package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;

public class DeleteAccountRequest {

    @NotBlank
    private String code; // Mã OTP xác nhận xóa tài khoản

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }
}
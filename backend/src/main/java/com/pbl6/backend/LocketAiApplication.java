package com.pbl6.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.transaction.annotation.EnableTransactionManagement;
import com.pbl6.backend.config.DotenvApplicationListener;

@SpringBootApplication
@EnableJpaRepositories
@EnableTransactionManagement
@EnableAsync
public class LocketAiApplication {

    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(LocketAiApplication.class);
        // Register dotenv listener early so System properties are available before binding
        app.addListeners(new DotenvApplicationListener());
        app.run(args);
    }

}
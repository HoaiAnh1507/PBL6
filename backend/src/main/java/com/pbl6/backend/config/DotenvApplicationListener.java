package com.pbl6.backend.config;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.context.event.ApplicationEnvironmentPreparedEvent;
import org.springframework.context.ApplicationListener;
// removed: import org.springframework.stereotype.Component;

// @Component // removed: we register this listener explicitly in main
public class DotenvApplicationListener implements ApplicationListener<ApplicationEnvironmentPreparedEvent> {

    @Override
    public void onApplicationEvent(ApplicationEnvironmentPreparedEvent event) {
        Dotenv dotenv = Dotenv.load();

        String dbUrl = dotenv.get("DB_URL");
        String dbUser = dotenv.get("DB_USERNAME");
        String dbPass = dotenv.get("DB_PASSWORD");

        if (dbUrl != null) System.setProperty("DB_URL", dbUrl);
        if (dbUser != null) System.setProperty("DB_USERNAME", dbUser);
        if (dbPass != null) System.setProperty("DB_PASSWORD", dbPass);

        System.out.println("Dotenv loaded: DB_URL=" + (dbUrl != null ? dbUrl : "<missing>") + 
                           ", DB_USERNAME=" + (dbUser != null ? dbUser : "<missing>") + 
                           ", DB_PASSWORD=<hidden>");
    }
}
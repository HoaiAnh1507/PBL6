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

        // Mail credentials
        String mailUser = dotenv.get("MAIL_USERNAME");
        String mailPass = dotenv.get("MAIL_PASSWORD");
        String mailFrom = dotenv.get("MAIL_FROM");
        String mailFromName = dotenv.get("MAIL_FROM_NAME");

        if (dbUrl != null) System.setProperty("DB_URL", dbUrl);
        if (dbUser != null) System.setProperty("DB_USERNAME", dbUser);
        if (dbPass != null) System.setProperty("DB_PASSWORD", dbPass);

        if (mailUser != null) System.setProperty("MAIL_USERNAME", mailUser);
        if (mailPass != null) System.setProperty("MAIL_PASSWORD", mailPass);
        if (mailFrom != null) System.setProperty("MAIL_FROM", mailFrom);
        if (mailFromName != null) System.setProperty("MAIL_FROM_NAME", mailFromName);

        System.out.println("Dotenv loaded: DB_URL=" + (dbUrl != null ? dbUrl : "<missing>") +
                ", DB_USERNAME=" + (dbUser != null ? dbUser : "<missing>") +
                ", DB_PASSWORD=<hidden>" +
                ", MAIL_USERNAME=" + (mailUser != null ? mailUser : "<missing>") +
                ", MAIL_PASSWORD=<hidden>" +
                ", MAIL_FROM=" + (mailFrom != null ? mailFrom : "<missing>") +
                ", MAIL_FROM_NAME=" + (mailFromName != null ? mailFromName : "<missing>"));
    }
}
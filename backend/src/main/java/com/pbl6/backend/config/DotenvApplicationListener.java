package com.pbl6.backend.config;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.context.event.ApplicationEnvironmentPreparedEvent;
import org.springframework.context.ApplicationListener;
// removed: import org.springframework.stereotype.Component;

// @Component // removed: we register this listener explicitly in main
public class DotenvApplicationListener implements ApplicationListener<ApplicationEnvironmentPreparedEvent> {

    @Override
    public void onApplicationEvent(ApplicationEnvironmentPreparedEvent event) {
        Dotenv dotenv = Dotenv.configure()
                .ignoreIfMissing()
                .load();

        // Database credentials
        String dbUrl = dotenv.get("DB_URL");
        String dbUser = dotenv.get("DB_USERNAME");
        String dbPass = dotenv.get("DB_PASSWORD");

        // Mail credentials
        String mailUser = dotenv.get("MAIL_USERNAME");
        String mailPass = dotenv.get("MAIL_PASSWORD");
        String mailFrom = dotenv.get("MAIL_FROM");
        String mailFromName = dotenv.get("MAIL_FROM_NAME");

        // Azure Service Bus credentials
        String azureConnectionString = dotenv.get("AZURE_SERVICEBUS_CONNECTION_STRING");
        String azureQueueName = dotenv.get("AZURE_QUEUE_NAME");

        
        // Azure Storage credentials
        String storageAccountName = dotenv.get("AZURE_STORAGE_ACCOUNT_NAME");
        String storageAccountKey = dotenv.get("AZURE_STORAGE_ACCOUNT_KEY");
        String storageConnectionString = dotenv.get("AZURE_STORAGE_CONNECTION_STRING");
        
        // AI Caption settings
        String aiCallbackSecret = dotenv.get("AI_CAPTION_CALLBACK_SECRET");

        // Set Database properties
        if (dbUrl != null)
            System.setProperty("DB_URL", dbUrl);
        if (dbUser != null)
            System.setProperty("DB_USERNAME", dbUser);
        if (dbPass != null)
            System.setProperty("DB_PASSWORD", dbPass);

        // Set Mail properties
        if (mailUser != null)
            System.setProperty("MAIL_USERNAME", mailUser);
        if (mailPass != null)
            System.setProperty("MAIL_PASSWORD", mailPass);
        if (mailFrom != null)
            System.setProperty("MAIL_FROM", mailFrom);
        if (mailFromName != null)
            System.setProperty("MAIL_FROM_NAME", mailFromName);

        // Set Azure properties
        if (azureConnectionString != null) System.setProperty("AZURE_SERVICEBUS_CONNECTION_STRING", azureConnectionString);
        if (azureQueueName != null) System.setProperty("AZURE_QUEUE_NAME", azureQueueName);
        // Set Azure Storage properties
        if (storageAccountName != null) System.setProperty("AZURE_STORAGE_ACCOUNT_NAME", storageAccountName);
        if (storageAccountKey != null) System.setProperty("AZURE_STORAGE_ACCOUNT_KEY", storageAccountKey);
        if (storageConnectionString != null) System.setProperty("AZURE_STORAGE_CONNECTION_STRING", storageConnectionString);
        
        // Set AI Caption properties
        if (aiCallbackSecret != null)
            System.setProperty("AI_CAPTION_CALLBACK_SECRET", aiCallbackSecret);

        System.out.println("✅ Dotenv loaded successfully:");
        System.out.println("   DB_URL=" + (dbUrl != null ? "configured" : "<missing>"));
        System.out.println("   DB_USERNAME=" + (dbUser != null ? "configured" : "<missing>"));
        System.out.println("   MAIL_USERNAME=" + (mailUser != null ? "configured" : "<missing>"));
        System.out.println("   AZURE_SERVICEBUS_CONNECTION_STRING="
                + (azureConnectionString != null ? "configured" : "<missing>"));
        System.out.println("   AZURE_QUEUE_NAME=" + (azureQueueName != null ? azureQueueName : "<missing>"));
        System.out.println("   AZURE_STORAGE_ACCOUNT_NAME=" + (storageAccountName != null ? "configured" : "<missing>"));
        System.out.println("   AZURE_STORAGE_ACCOUNT_KEY=" + (storageAccountKey != null ? "configured" : "<missing>"));
        System.out.println("   AZURE_STORAGE_CONNECTION_STRING=" + (storageConnectionString != null ? "configured" : "<missing>"));
        System.out.println("   AI_CAPTION_CALLBACK_SECRET=" + (aiCallbackSecret != null ? "configured" : "<missing>"));
    }
}
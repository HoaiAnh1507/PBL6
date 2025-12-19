---
title: LocketAI Backend
emoji: 🚀
colorFrom: blue
colorTo: green
sdk: docker
app_port: 7860
pinned: false
---

# PBL6 Backend - LocketAI Social Media Application

A Spring Boot backend application for a social media platform with AI-powered video caption generation and messaging functionality.

**🚀 Deployed on Hugging Face Spaces**

## Features

- User authentication and authorization with JWT
- User management with different subscription plans
- Post creation and management
- Real-time messaging between users
- Conversation management
- Role-based access control
- Comprehensive exception handling
- Input validation

## Technology Stack

- **Framework**: Spring Boot 2.7.x
- **Database**: MySQL
- **Security**: Spring Security with JWT
- **ORM**: Spring Data JPA
- **Validation**: Bean Validation (JSR-303)
- **Build Tool**: Maven

## Project Structure

```
src/main/java/com/pbl6/backend/
├── config/           # Configuration classes
├── controller/       # REST API controllers
├── exception/        # Custom exceptions and error handling
├── model/           # Entity classes
├── repository/      # Data access layer
├── request/         # Request DTOs
├── response/        # Response DTOs
├── security/        # Security configuration and JWT utilities
└── service/         # Business logic layer
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user info
- `POST /api/auth/validate` - Validate JWT token
- `POST /api/auth/refresh` - Refresh JWT token
- `POST /api/auth/logout` - User logout

### User Management
- `GET /api/users/{userId}` - Get user by ID
- `GET /api/users/username/{username}` - Get user by username
- `GET /api/users/search` - Search users by name
- `PUT /api/users/{userId}` - Update user profile
- `DELETE /api/users/{userId}` - Delete user account
- `PUT /api/users/{userId}/status` - Update account status (Admin only)
- `PUT /api/users/{userId}/subscription` - Update subscription plan
- `GET /api/users/stats/status` - Get user count by status (Admin only)
- `GET /api/users/stats/subscription` - Get user count by subscription (Admin only)

### Posts
- `POST /api/posts` - Create new post
- `GET /api/posts/{postId}` - Get post by ID
- `GET /api/posts/user/{userId}` - Get posts by user
- `GET /api/posts/search` - Search posts by content
- `GET /api/posts/status/{status}` - Get posts by status
- `PUT /api/posts/{postId}` - Update post
- `DELETE /api/posts/{postId}` - Delete post
- `PUT /api/posts/{postId}/status` - Update post status (Admin only)
- `GET /api/posts/recipient/{recipientId}` - Get posts for recipient
- `GET /api/posts/recent` - Get recent posts
- `GET /api/posts/count/user/{userId}` - Count posts by user
- `GET /api/posts/count/status/{status}` - Count posts by status (Admin only)

### Conversations
- `POST /api/conversations` - Create new conversation
- `GET /api/conversations/{conversationId}` - Get conversation by ID
- `GET /api/conversations` - Get user conversations
- `DELETE /api/conversations/{conversationId}` - Delete conversation
- `PUT /api/conversations/{conversationId}/last-message` - Update last message time
- `GET /api/conversations/count` - Count user conversations
- `GET /api/conversations/find` - Find conversation between users
- `GET /api/conversations/recent` - Get recent conversations

### Messages
- `POST /api/messages` - Send new message
- `GET /api/messages/{messageId}` - Get message by ID
- `GET /api/messages/conversation/{conversationId}` - Get conversation messages
- `DELETE /api/messages/{messageId}` - Delete message
- `GET /api/messages/count/conversation/{conversationId}` - Count messages by conversation
- `GET /api/messages/count/sender/{senderId}` - Count messages by sender
- `GET /api/messages/post/{postId}/replies` - Get messages replied to post

## Configuration

### Database Configuration
Update `application.properties` with your database settings:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/pbl6_db
spring.datasource.username=your_username
spring.datasource.password=your_password
```

### JWT Configuration
Configure JWT settings in `application.properties`:

```properties
app.jwt.secret=your_jwt_secret_key
app.jwt.expiration=86400000
```

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd backend
   ```

2. **Configure Database**
   - Create a MySQL database named `pbl6_db`
   - Update database credentials in `application.properties`

3. **Install Dependencies**
   ```bash
   mvn clean install
   ```

4. **Run the Application**
   ```bash
   mvn spring-boot:run
   ```

5. **Access the API**
   - Base URL: `http://localhost:8080`
   - API Documentation: Available through the endpoints listed above

## Security

- JWT-based authentication
- Role-based authorization (USER, ADMIN)
- Password encryption using BCrypt
- CORS configuration for cross-origin requests
- Method-level security annotations

## Error Handling

The application includes comprehensive error handling:

- Custom exception classes for different error types
- Global exception handler with appropriate HTTP status codes
- Validation error responses with field-specific messages
- Structured error responses with timestamps and request paths

## Data Models

### User
- User ID, username, email, password
- Full name, phone number, date of birth
- Account status (ACTIVE, INACTIVE, SUSPENDED)
- Subscription plan (FREE, PREMIUM, ENTERPRISE)
- Profile image and timestamps

### Post
- Post ID, content, media URLs
- Author, recipients, status
- Creation and update timestamps

### Message
- Message ID, content, sender
- Conversation reference
- Optional replied post reference
- Sent timestamp

### Conversation
- Conversation ID, participants
- Creation and last message timestamps

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.
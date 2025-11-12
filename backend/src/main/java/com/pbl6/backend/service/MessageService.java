package com.pbl6.backend.service;

import com.pbl6.backend.model.Conversation;
import com.pbl6.backend.model.Message;
import com.pbl6.backend.model.Post;
import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.ConversationRepository;
import com.pbl6.backend.repository.MessageRepository;
import com.pbl6.backend.repository.PostRepository;
import com.pbl6.backend.request.MessageSendRequest;
import com.pbl6.backend.request.ReplyPostMessageRequest;
import com.pbl6.backend.response.MessageResponse;
import com.pbl6.backend.response.PostResponse;
import com.pbl6.backend.response.UserResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class MessageService {
    private static final Logger log = LoggerFactory.getLogger(MessageService.class);

    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;
    private final PostRepository postRepository;
    private final AuthService authService;
    private final PostService postService;

    public MessageService(ConversationRepository conversationRepository,
                          MessageRepository messageRepository,
                          PostRepository postRepository,
                          AuthService authService,
                          PostService postService) {
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
        this.postRepository = postRepository;
        this.authService = authService;
        this.postService = postService;
    }

    @Transactional
    public MessageResponse sendMessage(User sender, MessageSendRequest req) {
        Conversation conv = conversationRepository.findById(req.getConversationId())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy hội thoại với id=" + req.getConversationId()));
        ensureMember(conv, sender);

        Message msg = new Message(conv, sender, req.getContent());
        msg = messageRepository.save(msg);
        updateConversationLastMessage(conv, msg.getSentAt());

        return toResponse(msg);
    }

    @Transactional
    public MessageResponse replyPost(User sender, ReplyPostMessageRequest req) {
        Post post = postRepository.findById(req.getPostId())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy post với id=" + req.getPostId()));

        // Tìm hội thoại giữa người reply (sender) và người đăng post; nếu chưa có thì tạo mới
        User postOwner = post.getUser();
        Conversation conv = conversationRepository.findByUsers(sender, postOwner)
                .orElseGet(() -> conversationRepository.save(new Conversation(sender, postOwner)));

        String content = (req.getContent() == null || req.getContent().isBlank()) ? "" : req.getContent();
        Message msg = new Message(conv, sender, content, post);
        msg = messageRepository.save(msg);
        updateConversationLastMessage(conv, msg.getSentAt());

        return toResponse(msg);
    }

    private void ensureMember(Conversation conv, User sender) {
        if (!conv.getUserOne().getUserId().equals(sender.getUserId()) &&
            !conv.getUserTwo().getUserId().equals(sender.getUserId())) {
            throw new RuntimeException("Bạn không thuộc hội thoại này");
        }
    }

    private void updateConversationLastMessage(Conversation conv, LocalDateTime at) {
        conv.setLastMessageAt(at != null ? at : LocalDateTime.now());
        conversationRepository.save(conv);
    }

    private MessageResponse toResponse(Message m) {
        UserResponse sender = authService.toUserResponse(m.getSender());
        PostResponse replied = null;
        if (m.getRepliedToPost() != null) {
            replied = postService.toResponse(m.getRepliedToPost());
        }
        return new MessageResponse(
                m.getMessageId(),
                m.getConversation().getConversationId(),
                sender,
                m.getContent(),
                replied,
                m.getSentAt(),
                m.isRead()
        );
    }

    @Transactional
    public void markAsRead(User currentUser, String messageId) {
        Message msg = messageRepository.findById(messageId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy tin nhắn với id=" + messageId));
        ensureMember(msg.getConversation(), currentUser);
        if (!msg.isRead()) {
            msg.setRead(true);
            messageRepository.save(msg);
        }
    }
}
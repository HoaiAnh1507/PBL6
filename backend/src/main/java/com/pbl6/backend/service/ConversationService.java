package com.pbl6.backend.service;

import com.pbl6.backend.model.Conversation;
import com.pbl6.backend.model.Message;
import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.ConversationRepository;
import com.pbl6.backend.repository.MessageRepository;
import com.pbl6.backend.response.ConversationResponse;
import com.pbl6.backend.response.MessageResponse;
import com.pbl6.backend.response.PostResponse;
import com.pbl6.backend.response.PublicUserResponse;
import com.pbl6.backend.response.UserResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.stream.Collectors;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Service
public class ConversationService {
    private static final Logger log = LoggerFactory.getLogger(ConversationService.class);

    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;
    private final UserService userService;
    private final AuthService authService;
    private final PostService postService;

    public ConversationService(ConversationRepository conversationRepository,
                               MessageRepository messageRepository,
                               UserService userService,
                               AuthService authService,
                               PostService postService) {
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
        this.userService = userService;
        this.authService = authService;
        this.postService = postService;
    }

    @Transactional(readOnly = true)
    public List<ConversationResponse> listMyConversations(User currentUser) {
        List<Conversation> convs = conversationRepository.findByUserOrderByLastMessageAtDesc(currentUser);
        List<ConversationResponse> res = new ArrayList<>();
        for (Conversation c : convs) {
            res.add(toConversationResponse(c, false));
        }
        return res;
    }

    @Transactional(readOnly = true)
    public ConversationResponse getMyConversation(User currentUser, String conversationId) {
        Conversation c = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy hội thoại với id=" + conversationId));
        if (!c.getUserOne().getUserId().equals(currentUser.getUserId()) &&
            !c.getUserTwo().getUserId().equals(currentUser.getUserId())) {
            throw new RuntimeException("Bạn không có quyền xem hội thoại này");
        }
        // Không load messages ở đây nữa, client sẽ gọi API riêng để load messages
        return toConversationResponse(c, false);
    }

    /**
     * Lấy tin nhắn của conversation với pagination (cursor-based)
     * Load 25 tin nhắn gần nhất, hoặc 25 tin trước messageId cho trước
     * @param currentUser user hiện tại
     * @param conversationId id cuộc hội thoại
     * @param beforeMessageId (optional) load tin nhắn trước tin này (dùng khi scroll lên)
     * @param limit số lượng tin nhắn (default 25, max 100)
     * @return danh sách tin nhắn, sắp xếp tăng dần theo thời gian
     */
    @Transactional(readOnly = true)
    public List<MessageResponse> getConversationMessages(User currentUser, String conversationId, 
                                                         String beforeMessageId, Integer limit) {
        Conversation c = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy hội thoại với id=" + conversationId));
        
        // Kiểm tra quyền truy cập
        if (!c.getUserOne().getUserId().equals(currentUser.getUserId()) &&
            !c.getUserTwo().getUserId().equals(currentUser.getUserId())) {
            throw new RuntimeException("Bạn không có quyền xem hội thoại này");
        }

        // Validate và set default limit (50 messages per load for chat)
        int pageSize = (limit == null || limit <= 0) ? 25 : Math.min(limit, 100);

        List<Message> messages;
        if (beforeMessageId != null && !beforeMessageId.isBlank()) {
            // Load tin nhắn cũ hơn (scroll lên) - Cursor-based
            Message beforeMessage = messageRepository.findById(beforeMessageId)
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy tin nhắn với id=" + beforeMessageId));
            messages = messageRepository.findByConversationAndSentAtBeforeOrderBySentAtDesc(
                    c, beforeMessage.getSentAt())
                    .stream()
                    .limit(pageSize)
                    .collect(Collectors.toList());
        } else {
            // Load tin nhắn mới nhất - Initial load
            messages = messageRepository.findTopNByConversationOrderBySentAtDesc(c)
                    .stream()
                    .limit(pageSize)
                    .collect(Collectors.toList());
        }

        // Reverse để sắp xếp tăng dần (cũ → mới) cho UI chat
        Collections.reverse(messages);

        // Convert to response
        List<MessageResponse> responses = new ArrayList<>();
        for (Message m : messages) {
            UserResponse sender = authService.toUserResponse(m.getSender());
            PostResponse replied = null;
            if (m.getRepliedToPost() != null) {
                replied = postService.toResponse(m.getRepliedToPost());
            }
            responses.add(new MessageResponse(
                    m.getMessageId(),
                    c.getConversationId(),
                    sender,
                    m.getContent(),
                    replied,
                    m.getSentAt(),
                    m.isRead()
            ));
        }

        return responses;
    }

    private ConversationResponse toConversationResponse(Conversation c, boolean includeMessages) {
        PublicUserResponse u1 = userService.toPublicUserResponse(c.getUserOne());
        PublicUserResponse u2 = userService.toPublicUserResponse(c.getUserTwo());

        List<MessageResponse> messages = Collections.emptyList();
        if (includeMessages) {
            List<Message> ms = messageRepository.findByConversationOrderBySentAtDesc(c);
            // chuyển sang tăng dần thời gian để hiển thị thuận tiện
            Collections.reverse(ms);
            messages = new ArrayList<>();
            for (Message m : ms) {
                UserResponse sender = authService.toUserResponse(m.getSender());
                PostResponse replied = null;
                if (m.getRepliedToPost() != null) {
                    replied = postService.toResponse(m.getRepliedToPost());
                }
                messages.add(new MessageResponse(
                        m.getMessageId(),
                        c.getConversationId(),
                        sender,
                        m.getContent(),
                        replied,
                        m.getSentAt(),
                        m.isRead()
                ));
            }
        }

        return new ConversationResponse(
                c.getConversationId(),
                u1,
                u2,
                c.getLastMessageAt(),
                c.getCreatedAt(),
                messages
        );
    }
}
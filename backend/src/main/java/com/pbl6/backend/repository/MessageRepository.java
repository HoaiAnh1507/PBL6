package com.pbl6.backend.repository;

import com.pbl6.backend.model.Conversation;
import com.pbl6.backend.model.Message;
import com.pbl6.backend.model.Post;
import com.pbl6.backend.model.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface MessageRepository extends JpaRepository<Message, String> {
    
    List<Message> findByConversation(Conversation conversation);
    
    Page<Message> findByConversation(Conversation conversation, Pageable pageable);
    
    List<Message> findByConversationOrderBySentAtDesc(Conversation conversation);
    
    Page<Message> findByConversationOrderBySentAtDesc(Conversation conversation, Pageable pageable);
    
    List<Message> findBySender(User sender);
    
    List<Message> findByRepliedToPost(Post repliedToPost);
    
    @Query("SELECT m FROM Message m WHERE m.conversation = :conversation ORDER BY m.sentAt DESC LIMIT 1")
    Optional<Message> findLatestMessageByConversation(@Param("conversation") Conversation conversation);
    
    @Query("SELECT m FROM Message m WHERE m.conversation = :conversation AND m.sentAt BETWEEN :startDate AND :endDate")
    List<Message> findByConversationAndSentAtBetween(@Param("conversation") Conversation conversation, 
                                                     @Param("startDate") LocalDateTime startDate, 
                                                     @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT COUNT(m) FROM Message m WHERE m.conversation = :conversation")
    long countByConversation(@Param("conversation") Conversation conversation);
    
    @Query("SELECT COUNT(m) FROM Message m WHERE m.sender = :sender")
    long countBySender(@Param("sender") User sender);
    
    @Query("SELECT COUNT(m) FROM Message m WHERE m.repliedToPost = :post")
    long countByRepliedToPost(@Param("post") Post post);
    
    // Cursor-based pagination methods for efficient message loading
    @Query("SELECT m FROM Message m WHERE m.conversation = :conversation ORDER BY m.sentAt DESC LIMIT :limit")
    List<Message> findTopNByConversationOrderBySentAtDesc(@Param("conversation") Conversation conversation, 
                                                           @Param("limit") int limit);
    
    @Query("SELECT m FROM Message m WHERE m.conversation = :conversation AND m.sentAt < :beforeTime ORDER BY m.sentAt DESC LIMIT :limit")
    List<Message> findByConversationAndSentAtBeforeOrderBySentAtDesc(@Param("conversation") Conversation conversation,
                                                                      @Param("beforeTime") LocalDateTime beforeTime,
                                                                      @Param("limit") int limit);
}
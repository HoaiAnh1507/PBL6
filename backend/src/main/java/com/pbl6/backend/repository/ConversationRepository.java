package com.pbl6.backend.repository;

import com.pbl6.backend.model.Conversation;
import com.pbl6.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, String> {
    
    @Query("SELECT c FROM Conversation c LEFT JOIN FETCH c.userOne LEFT JOIN FETCH c.userTwo WHERE (c.userOne = :user1 AND c.userTwo = :user2) OR (c.userOne = :user2 AND c.userTwo = :user1)")
    Optional<Conversation> findByUsers(@Param("user1") User user1, @Param("user2") User user2);
    
    @Query("SELECT DISTINCT c FROM Conversation c LEFT JOIN FETCH c.userOne LEFT JOIN FETCH c.userTwo WHERE c.userOne = :user OR c.userTwo = :user ORDER BY c.lastMessageAt DESC")
    List<Conversation> findByUserOrderByLastMessageAtDesc(@Param("user") User user);
    
    @Query("SELECT DISTINCT c FROM Conversation c LEFT JOIN FETCH c.userOne LEFT JOIN FETCH c.userTwo WHERE (c.userOne = :user OR c.userTwo = :user) AND c.lastMessageAt IS NOT NULL ORDER BY c.lastMessageAt DESC")
    List<Conversation> findActiveConversationsByUser(@Param("user") User user);
    
    @Query("SELECT COUNT(c) FROM Conversation c WHERE c.userOne = :user OR c.userTwo = :user")
    long countByUser(@Param("user") User user);
    
    boolean existsByUserOneAndUserTwo(User userOne, User userTwo);
}
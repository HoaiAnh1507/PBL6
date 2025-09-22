package com.pbl6.backend.repository;

import com.pbl6.backend.model.Friendship;
import com.pbl6.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FriendshipRepository extends JpaRepository<Friendship, String> {
    
    @Query("SELECT f FROM Friendship f WHERE (f.userOne = :user1 AND f.userTwo = :user2) OR (f.userOne = :user2 AND f.userTwo = :user1)")
    Optional<Friendship> findByUsers(@Param("user1") User user1, @Param("user2") User user2);
    
    @Query("SELECT f FROM Friendship f WHERE (f.userOne = :user OR f.userTwo = :user) AND f.status = :status")
    List<Friendship> findByUserAndStatus(@Param("user") User user, @Param("status") Friendship.FriendshipStatus status);
    
    @Query("SELECT f FROM Friendship f WHERE f.userTwo = :user AND f.status = 'PENDING'")
    List<Friendship> findPendingRequestsForUser(@Param("user") User user);
    
    @Query("SELECT f FROM Friendship f WHERE f.userOne = :user AND f.status = 'PENDING'")
    List<Friendship> findSentRequestsByUser(@Param("user") User user);
    
    @Query("SELECT CASE WHEN f.userOne = :user THEN f.userTwo ELSE f.userOne END FROM Friendship f WHERE (f.userOne = :user OR f.userTwo = :user) AND f.status = 'ACCEPTED'")
    List<User> findFriendsByUser(@Param("user") User user);
    
    @Query("SELECT COUNT(f) FROM Friendship f WHERE (f.userOne = :user OR f.userTwo = :user) AND f.status = 'ACCEPTED'")
    long countFriendsByUser(@Param("user") User user);
    
    @Query("SELECT COUNT(f) FROM Friendship f WHERE f.userTwo = :user AND f.status = 'PENDING'")
    long countPendingRequestsForUser(@Param("user") User user);
    
    boolean existsByUserOneAndUserTwo(User userOne, User userTwo);
}
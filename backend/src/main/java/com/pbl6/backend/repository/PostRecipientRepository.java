package com.pbl6.backend.repository;

import com.pbl6.backend.model.Post;
import com.pbl6.backend.model.PostRecipient;
import com.pbl6.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PostRecipientRepository extends JpaRepository<PostRecipient, String> {
    
    List<PostRecipient> findByPost(Post post);
    
    List<PostRecipient> findByRecipient(User recipient);
    
    @Query("SELECT pr.recipient FROM PostRecipient pr WHERE pr.post = :post")
    List<User> findRecipientsByPost(@Param("post") Post post);
    
    @Query("SELECT pr.post FROM PostRecipient pr WHERE pr.recipient = :recipient")
    List<Post> findPostsByRecipient(@Param("recipient") User recipient);
    
    boolean existsByPostAndRecipient(Post post, User recipient);
    
    void deleteByPostAndRecipient(Post post, User recipient);
    
    void deleteByPost(Post post);
}
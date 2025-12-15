import { useState, useEffect } from 'react';
import { Search, Filter, Eye, Trash2 } from 'lucide-react';
import Navbar from '../../components/Navbar';
import { getPosts, deletePost } from '../../api/adminApi';
import { formatDate, getStatusBadgeClass, getStatusText, debounce } from '../../utils/helpers';
import { preloadAvatarsWithSas, getAvatarWithSas, generateReadSasToken } from '../../api/storageApi';
import './ContentManagement.css';

const ContentManagement = () => {
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [mediaTypeFilter, setMediaTypeFilter] = useState('ALL');
  const [avatarUrls, setAvatarUrls] = useState({});
  const [mediaUrls, setMediaUrls] = useState({});
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [selectedPost, setSelectedPost] = useState(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleteReason, setDeleteReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [pagination, setPagination] = useState({
    page: 0,
    size: 20,
    totalPages: 0,
    totalElements: 0,
  });

  useEffect(() => {
    loadPosts();
  }, [searchTerm, mediaTypeFilter, statusFilter, pagination.page]);

  const loadPosts = async () => {
    setLoading(true);
    try {
      const params = {
        page: pagination.page,
        size: pagination.size,
      };
      if (searchTerm) params.search = searchTerm;
      if (mediaTypeFilter !== 'ALL') params.mediaType = mediaTypeFilter;
      if (statusFilter !== 'ALL') params.status = statusFilter;

      const response = await getPosts(params);
      const postList = response.content || response;
      setPosts(postList);
      
      // Preload avatar SAS tokens
      const users = postList.map(p => p.user).filter(u => u);
      await preloadAvatarsWithSas(users);
      
      // Generate avatar URLs with SAS tokens
      const avatars = {};
      await Promise.all(postList.map(async (post) => {
        if (post.user) {
          avatars[post.user.userId] = await getAvatarWithSas(post.user.profilePictureUrl, post.user.fullName);
        }
      }));
      setAvatarUrls(avatars);
      
      // Generate media URLs with SAS tokens
      const media = {};
      await Promise.all(postList.map(async (post) => {
        if (post.mediaUrl?.includes('.blob.core.windows.net')) {
          const signedUrl = await generateReadSasToken(post.mediaUrl);
          media[post.postId] = signedUrl || post.mediaUrl;
        } else {
          media[post.postId] = post.mediaUrl;
        }
      }));
      setMediaUrls(media);
      
      if (response.totalPages) {
        setPagination(prev => ({
          ...prev,
          totalPages: response.totalPages,
          totalElements: response.totalElements,
        }));
      }
    } catch (error) {
      console.error('Error loading posts:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSearchChange = debounce((value) => {
    setSearchTerm(value);
    setPagination(prev => ({ ...prev, page: 0 }));
  }, 500);

  const openDeleteModal = (post) => {
    setSelectedPost(post);
    setDeleteReason('');
    setShowDeleteModal(true);
  };

  const handleDelete = async () => {
    if (!deleteReason.trim()) {
      alert('Vui lòng nhập lý do xóa');
      return;
    }

    setActionLoading(true);
    try {
      await deletePost(selectedPost.postId, deleteReason);
      alert('Xóa bài viết thành công');
      setShowDeleteModal(false);
      loadPosts();
    } catch (error) {
      alert('Có lỗi xảy ra: ' + (error.response?.data?.message || error.message));
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <>
      <Navbar />
      <div className="container content-management">
        <div className="page-header">
          <h1>Quản lý nội dung</h1>
          <div className="page-stats">
            <span>Tổng: {pagination.totalElements}</span>
          </div>
        </div>

        <div className="card filters-section">
          <div className="search-box">
            <Search size={20} />
            <input
              type="text"
              placeholder="Tìm kiếm bài viết..."
              onChange={(e) => handleSearchChange(e.target.value)}
            />
          </div>

          <div className="filters">
            <div className="filter-group">
              <Filter size={18} />
              <select value={mediaTypeFilter} onChange={(e) => setMediaTypeFilter(e.target.value)}>
                <option value="ALL">Tất cả loại</option>
                <option value="PHOTO">Ảnh</option>
                <option value="VIDEO">Video</option>
              </select>
            </div>

            <div className="filter-group">
              <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
                <option value="ALL">Tất cả trạng thái</option>
                <option value="PENDING">Đang xử lý</option>
                <option value="COMPLETED">Hoàn thành</option>
                <option value="FAILED">Thất bại</option>
              </select>
            </div>
          </div>
        </div>

        {loading ? (
          <div className="loading">Đang tải...</div>
        ) : (
          <>
            <div className="posts-grid">
              {posts.map((post) => (
                <div key={post.postId} className="post-card">
                  <div className="post-media">
                    {post.mediaType === 'PHOTO' ? (
                      <img 
                        src={mediaUrls[post.postId] || post.mediaUrl} 
                        alt="Post"
                        onError={(e) => {
                          e.target.style.display = 'none';
                          e.target.parentElement.style.backgroundColor = '#f0f0f0';
                        }}
                      />
                    ) : (
                      <video 
                        src={mediaUrls[post.postId] || post.mediaUrl}
                        onError={(e) => {
                          e.target.style.display = 'none';
                          e.target.parentElement.style.backgroundColor = '#f0f0f0';
                        }}
                      />
                    )}
                    <div className="post-type-badge">
                      {post.mediaType === 'PHOTO' ? '📷' : '🎥'}
                    </div>
                  </div>

                  <div className="post-content">
                    <div className="post-author">
                      <img
                        src={avatarUrls[post.user?.userId] || 'https://ui-avatars.com/api/?name=' + encodeURIComponent(post.user?.fullName || 'User') + '&background=0D8ABC&color=fff'}
                        alt={post.user?.fullName}
                        className="post-author-avatar"
                        onError={(e) => {
                          e.target.onerror = null;
                          e.target.src = 'https://ui-avatars.com/api/?name=' + encodeURIComponent(post.user?.fullName || 'User') + '&background=0D8ABC&color=fff';
                        }}
                      />
                      <div>
                        <div className="post-author-name">{post.user?.fullName}</div>
                        <div className="post-date">{formatDate(post.createdAt)}</div>
                      </div>
                    </div>

                    <div className="post-caption">
                      {post.finalCaption || post.generatedCaption || 'Chưa có caption'}
                    </div>

                    <div className="post-meta">
                      <span className={`badge ${getStatusBadgeClass(post.captionStatus)}`}>
                        {getStatusText(post.captionStatus)}
                      </span>
                    </div>

                    <div className="post-actions">
                      <button
                        className="btn btn-primary btn-sm"
                        onClick={() => setSelectedPost(post)}
                        title="Xem chi tiết"
                      >
                        <Eye size={16} />
                        <span>Xem</span>
                      </button>
                      <button
                        className="btn btn-danger btn-sm"
                        onClick={() => openDeleteModal(post)}
                        title="Xóa"
                      >
                        <Trash2 size={16} />
                        <span>Xóa</span>
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {pagination.totalPages > 1 && (
              <div className="pagination">
                <button
                  className="btn btn-secondary"
                  onClick={() => setPagination(prev => ({ ...prev, page: prev.page - 1 }))}
                  disabled={pagination.page === 0}
                >
                  Trang trước
                </button>
                <span>
                  Trang {pagination.page + 1} / {pagination.totalPages}
                </span>
                <button
                  className="btn btn-secondary"
                  onClick={() => setPagination(prev => ({ ...prev, page: prev.page + 1 }))}
                  disabled={pagination.page >= pagination.totalPages - 1}
                >
                  Trang sau
                </button>
              </div>
            )}
          </>
        )}

        {/* Delete Modal */}
        {showDeleteModal && (
          <div className="modal-overlay" onClick={() => setShowDeleteModal(false)}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2>Xóa bài viết</h2>
                <button className="close-btn" onClick={() => setShowDeleteModal(false)}>×</button>
              </div>

              <div className="modal-body">
                <p>
                  Bạn có chắc chắn muốn xóa bài viết này?
                </p>

                <div className="form-group">
                  <label>Lý do xóa *</label>
                  <textarea
                    value={deleteReason}
                    onChange={(e) => setDeleteReason(e.target.value)}
                    placeholder="Nhập lý do xóa bài viết..."
                    rows="4"
                    required
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button className="btn btn-secondary" onClick={() => setShowDeleteModal(false)}>
                  Hủy
                </button>
                <button
                  className="btn btn-danger"
                  onClick={handleDelete}
                  disabled={actionLoading}
                >
                  {actionLoading ? 'Đang xóa...' : 'Xác nhận xóa'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Post Detail Modal */}
        {selectedPost && !showDeleteModal && (
          <div className="modal-overlay" onClick={() => setSelectedPost(null)}>
            <div className="modal-content modal-large" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2>Chi tiết bài viết</h2>
                <button className="close-btn" onClick={() => setSelectedPost(null)}>×</button>
              </div>

              <div className="modal-body post-detail">
                <div className="post-detail-media">
                  {selectedPost.mediaType === 'PHOTO' ? (
                    <img src={mediaUrls[selectedPost.postId] || selectedPost.mediaUrl} alt="Post" />
                  ) : (
                    <video src={mediaUrls[selectedPost.postId] || selectedPost.mediaUrl} controls />
                  )}
                </div>

                <div className="detail-section">
                  <h3>Người đăng</h3>
                  <div className="user-info-large">
                    <img
                      src={avatarUrls[selectedPost.user?.userId] || 'https://ui-avatars.com/api/?name=' + encodeURIComponent(selectedPost.user?.fullName || 'User') + '&background=0D8ABC&color=fff'}
                      alt={selectedPost.user?.fullName}
                      className="user-avatar-large"
                      onError={(e) => {
                        e.target.onerror = null;
                        e.target.src = 'https://ui-avatars.com/api/?name=' + encodeURIComponent(selectedPost.user?.fullName || 'User') + '&background=0D8ABC&color=fff';
                      }}
                    />
                    <div>
                      <div className="user-name">{selectedPost.user?.fullName}</div>
                      <div className="user-username">@{selectedPost.user?.username}</div>
                      <div className="user-email">{selectedPost.user?.email}</div>
                    </div>
                  </div>
                </div>

                <div className="detail-section">
                  <h3>Thông tin bài viết</h3>
                  <div className="info-row">
                    <span className="info-label">Loại:</span>
                    <span className="badge badge-info">
                      {selectedPost.mediaType === 'PHOTO' ? 'Ảnh' : 'Video'}
                    </span>
                  </div>
                  <div className="info-row">
                    <span className="info-label">Trạng thái caption:</span>
                    <span className={`badge ${getStatusBadgeClass(selectedPost.captionStatus)}`}>
                      {getStatusText(selectedPost.captionStatus)}
                    </span>
                  </div>
                  <div className="info-row">
                    <span className="info-label">Ngày tạo:</span>
                    <span>{formatDate(selectedPost.createdAt)}</span>
                  </div>
                </div>

                {selectedPost.generatedCaption && (
                  <div className="detail-section">
                    <h3>AI Generated Caption</h3>
                    <p className="caption-text">{selectedPost.generatedCaption}</p>
                  </div>
                )}

                {selectedPost.finalCaption && (
                  <div className="detail-section">
                    <h3>Final Caption</h3>
                    <p className="caption-text">{selectedPost.finalCaption}</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </>
  );
};

export default ContentManagement;

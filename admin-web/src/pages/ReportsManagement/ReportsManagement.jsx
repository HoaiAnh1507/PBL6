import { useState, useEffect } from 'react';
import { Search, Filter, Eye, CheckCircle, XCircle } from 'lucide-react';
import Navbar from '../../components/Navbar';
import { getReports, resolveReport, deletePost as deletePostApi, updateUserStatus } from '../../api/adminApi';
import { formatDate, getStatusBadgeClass, getStatusText, debounce } from '../../utils/helpers';
import { preloadAvatarsWithSas, getAvatarWithSas, generateReadSasToken } from '../../api/storageApi';
import './ReportsManagement.css';

const ReportsManagement = () => {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('PENDING');
  const [selectedReport, setSelectedReport] = useState(null);
  const [showResolveModal, setShowResolveModal] = useState(false);
  const [resolveAction, setResolveAction] = useState('');
  const [resolutionNotes, setResolutionNotes] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  
  // New states for actions
  const [deletePost, setDeletePost] = useState(false);
  const [userAction, setUserAction] = useState('NONE'); // NONE, SUSPEND, BAN
  
  // SAS token states
  const [avatarUrls, setAvatarUrls] = useState({});
  const [mediaUrls, setMediaUrls] = useState({});
  
  const [pagination, setPagination] = useState({
    page: 0,
    size: 20,
    totalPages: 0,
    totalElements: 0,
  });

  useEffect(() => {
    loadReports();
  }, [statusFilter, pagination.page]);

  const loadReports = async () => {
    setLoading(true);
    try {
      const params = {
        page: pagination.page,
        size: pagination.size,
      };
      if (statusFilter !== 'ALL') params.status = statusFilter;

      const response = await getReports(params);
      const reportList = response.content || response;
      setReports(reportList);
      
      // Collect all users
      const users = [];
      reportList.forEach(r => {
        if (r.reporter) users.push(r.reporter);
        if (r.reportedUser) users.push(r.reportedUser);
        if (r.reportedPost?.user) users.push(r.reportedPost.user);
      });
      await preloadAvatarsWithSas(users);
      
      // Generate avatar URLs
      const avatars = {};
      await Promise.all(users.map(async (user) => {
        if (user && !avatars[user.userId]) {
          avatars[user.userId] = await getAvatarWithSas(user.profilePictureUrl, user.fullName);
        }
      }));
      setAvatarUrls(avatars);
      
      // Generate media URLs for reported posts
      const media = {};
      await Promise.all(reportList.map(async (report) => {
        if (report.reportedPost?.mediaUrl?.includes('.blob.core.windows.net')) {
          const signedUrl = await generateReadSasToken(report.reportedPost.mediaUrl);
          media[report.reportedPost.postId] = signedUrl || report.reportedPost.mediaUrl;
        } else if (report.reportedPost?.mediaUrl) {
          media[report.reportedPost.postId] = report.reportedPost.mediaUrl;
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
      console.error('Error loading reports:', error);
    } finally {
      setLoading(false);
    }
  };

  const openResolveModal = (report, action) => {
    setSelectedReport(report);
    setResolveAction(action);
    setResolutionNotes('');
    setDeletePost(false);
    setUserAction('NONE');
    setShowResolveModal(true);
  };

  const handleResolve = async () => {
    if (!resolutionNotes.trim()) {
      alert('Vui lòng nhập ghi chú xử lý');
      return;
    }

    setActionLoading(true);
    try {
      // Build resolution notes with actions taken
      let fullNotes = resolutionNotes;
      const actionsTaken = [];

      // 1. Delete post if checked
      if (deletePost && selectedReport.reportedPost) {
        try {
          await deletePostApi(selectedReport.reportedPost.postId, 'Bài viết vi phạm theo báo cáo #' + selectedReport.reportId);
          actionsTaken.push('✓ Đã xóa bài viết');
        } catch (error) {
          console.error('Error deleting post:', error);
          actionsTaken.push('✗ Lỗi khi xóa bài viết: ' + (error.response?.data || error.message));
        }
      }

      // 2. Take action on user account if selected
      if (userAction !== 'NONE' && selectedReport.reportedUser) {
        try {
          const statusMap = {
            'SUSPEND': 'SUSPENDED',
            'BAN': 'BANNED'
          };
          await updateUserStatus(
            selectedReport.reportedUser.userId, 
            statusMap[userAction], 
            'Vi phạm theo báo cáo #' + selectedReport.reportId
          );
          const actionText = userAction === 'SUSPEND' ? 'tạm khóa' : 'khóa vĩnh viễn';
          actionsTaken.push(`✓ Đã ${actionText} tài khoản`);
        } catch (error) {
          console.error('Error updating user status:', error);
          actionsTaken.push('✗ Lỗi khi cập nhật trạng thái user: ' + (error.response?.data || error.message));
        }
      }

      // Append actions taken to notes
      if (actionsTaken.length > 0) {
        fullNotes += '\n\n--- Hành động đã thực hiện ---\n' + actionsTaken.join('\n');
      }

      // 3. Resolve the report
      await resolveReport(selectedReport.reportId, resolveAction, fullNotes);
      
      alert('Xử lý báo cáo thành công!' + (actionsTaken.length > 0 ? '\n\n' + actionsTaken.join('\n') : ''));
      setShowResolveModal(false);
      loadReports();
    } catch (error) {
      alert('Có lỗi xảy ra: ' + (error.response?.data?.message || error.message));
    } finally {
      setActionLoading(false);
    }
  };

  const getReportTypeText = (report) => {
    if (report.reportedPost) return 'Bài viết';
    if (report.reportedUser) return 'Người dùng';
    return 'Khác';
  };

  return (
    <>
      <Navbar />
      <div className="container reports-management">
        <div className="page-header">
          <h1>Quản lý báo cáo</h1>
          <div className="page-stats">
            <span>Tổng: {pagination.totalElements}</span>
          </div>
        </div>

        <div className="card filters-section">
          <div className="filters">
            <div className="filter-group">
              <Filter size={18} />
              <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
                <option value="ALL">Tất cả trạng thái</option>
                <option value="PENDING">Chờ xử lý</option>
                <option value="RESOLVED">Đã xử lý</option>
                <option value="DISMISSED">Đã bỏ qua</option>
              </select>
            </div>
          </div>
        </div>

        {loading ? (
          <div className="loading">Đang tải...</div>
        ) : (
          <>
            <div className="card table-container">
              <table>
                <thead>
                  <tr>
                    <th>Loại</th>
                    <th>Người báo cáo</th>
                    <th>Đối tượng bị báo cáo</th>
                    <th>Lý do</th>
                    <th>Trạng thái</th>
                    <th>Ngày tạo</th>
                    <th>Hành động</th>
                  </tr>
                </thead>
                <tbody>
                  {reports.map((report) => (
                    <tr key={report.reportId}>
                      <td>
                        <span className="badge badge-info">{getReportTypeText(report)}</span>
                      </td>
                      <td>
                        <div className="user-info">
                          <div>
                            <div className="user-name">{report.reporter?.fullName}</div>
                            <div className="user-username">@{report.reporter?.username}</div>
                          </div>
                        </div>
                      </td>
                      <td>
                        {report.reportedPost && (
                          <div className="reported-item">
                            <span>Post ID: {report.reportedPost.postId?.substring(0, 8)}...</span>
                          </div>
                        )}
                        {report.reportedUser && (
                          <div className="user-info">
                            <div>
                              <div className="user-name">{report.reportedUser.fullName}</div>
                              <div className="user-username">@{report.reportedUser.username}</div>
                            </div>
                          </div>
                        )}
                      </td>
                      <td>
                        <div className="reason-text">{report.reason}</div>
                      </td>
                      <td>
                        <span className={`badge ${getStatusBadgeClass(report.status)}`}>
                          {getStatusText(report.status)}
                        </span>
                      </td>
                      <td>{formatDate(report.createdAt)}</td>
                      <td>
                        <div className="action-buttons">
                          <button
                            className="btn btn-primary btn-sm"
                            onClick={() => setSelectedReport(report)}
                            title="Xem chi tiết"
                          >
                            <Eye size={16} />
                          </button>
                          {report.status === 'PENDING' && (
                            <>
                              <button
                                className="btn btn-success btn-sm"
                                onClick={() => openResolveModal(report, 'RESOLVED')}
                                title="Xử lý"
                              >
                                <CheckCircle size={16} />
                              </button>
                              <button
                                className="btn btn-secondary btn-sm"
                                onClick={() => openResolveModal(report, 'DISMISSED')}
                                title="Bỏ qua"
                              >
                                <XCircle size={16} />
                              </button>
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
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

        {/* Resolve Modal */}
        {showResolveModal && (
          <div className="modal-overlay" onClick={() => setShowResolveModal(false)}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2>{resolveAction === 'RESOLVED' ? 'Xử lý báo cáo' : 'Bỏ qua báo cáo'}</h2>
                <button className="close-btn" onClick={() => setShowResolveModal(false)}>×</button>
              </div>

              <div className="modal-body">
                {resolveAction === 'RESOLVED' && (
                  <>
                    {/* Delete Post Option */}
                    {selectedReport?.reportedPost && (
                      <div className="form-group">
                        <label className="checkbox-label">
                          <input
                            type="checkbox"
                            checked={deletePost}
                            onChange={(e) => setDeletePost(e.target.checked)}
                          />
                          <span>Xóa bài viết bị báo cáo</span>
                        </label>
                      </div>
                    )}

                    {/* User Action Option */}
                    {selectedReport?.reportedUser && (
                      <div className="form-group">
                        <label>Hành động với người dùng</label>
                        <select 
                          value={userAction} 
                          onChange={(e) => setUserAction(e.target.value)}
                          className="form-control"
                        >
                          <option value="NONE">Không thực hiện</option>
                          <option value="SUSPEND">Tạm khóa tài khoản</option>
                          <option value="BAN">Khóa vĩnh viễn</option>
                        </select>
                      </div>
                    )}

                    <hr style={{ margin: '20px 0', border: '1px solid #e0e0e0' }} />
                  </>
                )}

                <div className="form-group">
                  <label>Ghi chú xử lý *</label>
                  <textarea
                    value={resolutionNotes}
                    onChange={(e) => setResolutionNotes(e.target.value)}
                    placeholder="Nhập ghi chú về cách xử lý..."
                    rows="4"
                    required
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button className="btn btn-secondary" onClick={() => setShowResolveModal(false)}>
                  Hủy
                </button>
                <button
                  className={`btn ${resolveAction === 'RESOLVED' ? 'btn-success' : 'btn-secondary'}`}
                  onClick={handleResolve}
                  disabled={actionLoading}
                >
                  {actionLoading ? 'Đang xử lý...' : 'Xác nhận'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Report Detail Modal */}
        {selectedReport && !showResolveModal && (
          <div className="modal-overlay" onClick={() => setSelectedReport(null)}>
            <div className="modal-content modal-large" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2>Chi tiết báo cáo</h2>
                <button className="close-btn" onClick={() => setSelectedReport(null)}>×</button>
              </div>

              <div className="modal-body report-detail">
                <div className="detail-section">
                  <h3>Thông tin báo cáo</h3>
                  <div className="info-row">
                    <span className="info-label">Loại:</span>
                    <span className="badge badge-info">{getReportTypeText(selectedReport)}</span>
                  </div>
                  <div className="info-row">
                    <span className="info-label">Trạng thái:</span>
                    <span className={`badge ${getStatusBadgeClass(selectedReport.status)}`}>
                      {getStatusText(selectedReport.status)}
                    </span>
                  </div>
                  <div className="info-row">
                    <span className="info-label">Ngày tạo:</span>
                    <span>{formatDate(selectedReport.createdAt)}</span>
                  </div>
                  {selectedReport.resolvedAt && (
                    <div className="info-row">
                      <span className="info-label">Ngày xử lý:</span>
                      <span>{formatDate(selectedReport.resolvedAt)}</span>
                    </div>
                  )}
                </div>

                <div className="detail-section">
                  <h3>Người báo cáo</h3>
                  <div className="user-info-large">
                    <img
                      src={avatarUrls[selectedReport.reporter?.userId] || 'https://ui-avatars.com/api/?name=' + encodeURIComponent(selectedReport.reporter?.fullName || 'User') + '&background=0D8ABC&color=fff'}
                      alt={selectedReport.reporter?.fullName}
                      className="user-avatar-large"
                      onError={(e) => {
                        e.target.onerror = null;
                        e.target.src = 'https://ui-avatars.com/api/?name=' + encodeURIComponent(selectedReport.reporter?.fullName || 'User') + '&background=0D8ABC&color=fff';
                      }}
                    />
                    <div>
                      <div className="user-name">{selectedReport.reporter?.fullName}</div>
                      <div className="user-username">@{selectedReport.reporter?.username}</div>
                      <div className="user-email">{selectedReport.reporter?.email}</div>
                    </div>
                  </div>
                </div>

                <div className="detail-section">
                  <h3>Lý do</h3>
                  <p className="reason-full">{selectedReport.reason}</p>
                </div>

                {selectedReport.reportedPost && (
                  <div className="detail-section">
                    <h3>Bài viết bị báo cáo</h3>
                    <div className="post-preview">
                      {selectedReport.reportedPost.mediaType === 'PHOTO' ? (
                        <img src={mediaUrls[selectedReport.reportedPost.postId] || selectedReport.reportedPost.mediaUrl} alt="Post" />
                      ) : (
                        <video src={mediaUrls[selectedReport.reportedPost.postId] || selectedReport.reportedPost.mediaUrl} controls />
                      )}
                      <p>{selectedReport.reportedPost.finalCaption || selectedReport.reportedPost.generatedCaption}</p>
                    </div>
                  </div>
                )}

                {selectedReport.reportedUser && (
                  <div className="detail-section">
                    <h3>Người dùng bị báo cáo</h3>
                    <div className="user-info-large">
                      <img
                        src={avatarUrls[selectedReport.reportedUser?.userId] || 'https://ui-avatars.com/api/?name=' + encodeURIComponent(selectedReport.reportedUser?.fullName || 'User') + '&background=0D8ABC&color=fff'}
                        alt={selectedReport.reportedUser?.fullName}
                        className="user-avatar-large"
                        onError={(e) => {
                          e.target.onerror = null;
                          e.target.src = 'https://ui-avatars.com/api/?name=' + encodeURIComponent(selectedReport.reportedUser?.fullName || 'User') + '&background=0D8ABC&color=fff';
                        }}
                      />
                      <div>
                        <div className="user-name">{selectedReport.reportedUser?.fullName}</div>
                        <div className="user-username">@{selectedReport.reportedUser?.username}</div>
                        <div className="user-email">{selectedReport.reportedUser?.email}</div>
                      </div>
                    </div>
                  </div>
                )}

                {selectedReport.resolutionNotes && (
                  <div className="detail-section">
                    <h3>Ghi chú xử lý</h3>
                    <p>{selectedReport.resolutionNotes}</p>
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

export default ReportsManagement;

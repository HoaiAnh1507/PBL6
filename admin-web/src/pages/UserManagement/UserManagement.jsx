import { useState, useEffect } from 'react';
import { Search, Filter, Eye, Ban, AlertCircle } from 'lucide-react';
import Navbar from '../../components/Navbar';
import { getUsers, updateUserStatus } from '../../api/adminApi';
import { formatDate, formatNumber, getStatusBadgeClass, getStatusText, debounce } from '../../utils/helpers';
import { preloadAvatarsWithSas, getAvatarWithSas } from '../../api/storageApi';
import './UserManagement.css';

const UserManagement = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [avatarUrls, setAvatarUrls] = useState({});
  const [subscriptionFilter, setSubscriptionFilter] = useState('ALL');
  const [selectedUser, setSelectedUser] = useState(null);
  const [showActionModal, setShowActionModal] = useState(false);
  const [actionType, setActionType] = useState('');
  const [actionReason, setActionReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [pagination, setPagination] = useState({
    page: 0,
    size: 20,
    totalPages: 0,
    totalElements: 0,
  });

  useEffect(() => {
    loadUsers();
  }, [searchTerm, statusFilter, subscriptionFilter, pagination.page]);

  const loadUsers = async () => {
    setLoading(true);
    try {
      const params = {
        page: pagination.page,
        size: pagination.size,
      };
      if (searchTerm) params.search = searchTerm;
      if (statusFilter !== 'ALL') params.status = statusFilter;
      if (subscriptionFilter !== 'ALL') params.subscription = subscriptionFilter;

      const response = await getUsers(params);
      const userList = response.content || response;
      setUsers(userList);
      
      // Preload avatar SAS tokens
      await preloadAvatarsWithSas(userList);
      
      // Generate avatar URLs with SAS tokens
      const urls = {};
      await Promise.all(userList.map(async (user) => {
        urls[user.userId] = await getAvatarWithSas(user.profilePictureUrl, user.fullName);
      }));
      setAvatarUrls(urls);
      
      if (response.totalPages) {
        setPagination(prev => ({
          ...prev,
          totalPages: response.totalPages,
          totalElements: response.totalElements,
        }));
      }
    } catch (error) {
      console.error('Error loading users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSearchChange = debounce((value) => {
    setSearchTerm(value);
    setPagination(prev => ({ ...prev, page: 0 }));
  }, 500);

  const openActionModal = (user, action) => {
    setSelectedUser(user);
    setActionType(action);
    setActionReason('');
    setShowActionModal(true);
  };

  const handleAction = async () => {
    if (!actionReason.trim()) {
      alert('Vui lòng nhập lý do');
      return;
    }

    setActionLoading(true);
    try {
      await updateUserStatus(selectedUser.userId, actionType, actionReason);
      alert('Cập nhật trạng thái thành công');
      setShowActionModal(false);
      setSelectedUser(null); // Reset to prevent detail modal from showing
      loadUsers();
    } catch (error) {
      alert('Có lỗi xảy ra: ' + (error.response?.data?.message || error.message));
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <>
      <Navbar />
      <div className="container user-management">
        <div className="page-header">
          <h1>Quản lý người dùng</h1>
          <div className="page-stats">
            <span>Tổng: {formatNumber(pagination.totalElements)}</span>
          </div>
        </div>

        <div className="card filters-section">
          <div className="search-box">
            <Search size={20} />
            <input
              type="text"
              placeholder="Tìm kiếm theo tên, email, username..."
              onChange={(e) => handleSearchChange(e.target.value)}
            />
          </div>

          <div className="filters">
            <div className="filter-group">
              <Filter size={18} />
              <select value={statusFilter} onChange={(e) => {
                setStatusFilter(e.target.value);
                setPagination(prev => ({ ...prev, page: 0 }));
              }}>
                <option value="ALL">Tất cả trạng thái</option>
                <option value="ACTIVE">Hoạt động</option>
                <option value="SUSPENDED">Tạm khóa</option>
                <option value="BANNED">Cấm</option>
              </select>
            </div>

            <div className="filter-group">
              <select value={subscriptionFilter} onChange={(e) => {
                setSubscriptionFilter(e.target.value);
                setPagination(prev => ({ ...prev, page: 0 }));
              }}>
                <option value="ALL">Tất cả gói</option>
                <option value="FREE">Free</option>
                <option value="GOLD">Gold</option>
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
                    <th>Người dùng</th>
                    <th>Email</th>
                    <th>Số điện thoại</th>
                    <th>Trạng thái</th>
                    <th>Gói</th>
                    <th>Ngày tạo</th>
                    <th>Hành động</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((user) => (
                    <tr key={user.userId}>
                      <td>
                        <div className="user-info">
                          <img
                            src={avatarUrls[user.userId] || 'https://ui-avatars.com/api/?name=' + encodeURIComponent(user.fullName) + '&background=0D8ABC&color=fff'}
                            alt={user.fullName}
                            className="user-avatar"
                            onError={(e) => {
                              e.target.onerror = null;
                              e.target.src = 'https://ui-avatars.com/api/?name=' + encodeURIComponent(user.fullName) + '&background=0D8ABC&color=fff';
                            }}
                          />
                          <div>
                            <div className="user-name">{user.fullName}</div>
                            <div className="user-username">@{user.username}</div>
                          </div>
                        </div>
                      </td>
                      <td>{user.email}</td>
                      <td>{user.phoneNumber}</td>
                      <td>
                        <span className={`badge ${getStatusBadgeClass(user.accountStatus)}`}>
                          {getStatusText(user.accountStatus)}
                        </span>
                      </td>
                      <td>
                        <span className={`badge ${user.subscriptionStatus === 'GOLD' ? 'badge-warning' : 'badge-secondary'}`}>
                          {getStatusText(user.subscriptionStatus)}
                        </span>
                      </td>
                      <td>{formatDate(user.createdAt)}</td>
                      <td>
                        <div className="action-buttons">
                          <button
                            className="btn btn-primary btn-sm"
                            onClick={() => setSelectedUser(user)}
                            title="Xem chi tiết"
                          >
                            <Eye size={16} />
                          </button>
                          {user.accountStatus === 'ACTIVE' && (
                            <>
                              <button
                                className="btn btn-warning btn-sm"
                                onClick={() => openActionModal(user, 'SUSPENDED')}
                                title="Tạm khóa"
                              >
                                <AlertCircle size={16} />
                              </button>
                              <button
                                className="btn btn-danger btn-sm"
                                onClick={() => openActionModal(user, 'BANNED')}
                                title="Cấm vĩnh viễn"
                              >
                                <Ban size={16} />
                              </button>
                            </>
                          )}
                          {user.accountStatus !== 'ACTIVE' && (
                            <button
                              className="btn btn-success btn-sm"
                              onClick={() => openActionModal(user, 'ACTIVE')}
                              title="Kích hoạt lại"
                            >
                              Mở khóa
                            </button>
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

        {/* Action Modal */}
        {showActionModal && (
          <div className="modal-overlay" onClick={() => setShowActionModal(false)}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2>
                  {actionType === 'ACTIVE' && 'Mở khóa tài khoản'}
                  {actionType === 'SUSPENDED' && 'Tạm khóa tài khoản'}
                  {actionType === 'BANNED' && 'Cấm tài khoản'}
                </h2>
                <button className="close-btn" onClick={() => setShowActionModal(false)}>×</button>
              </div>

              <div className="modal-body">
                <p>
                  Bạn có chắc chắn muốn {actionType === 'ACTIVE' ? 'mở khóa' : actionType === 'SUSPENDED' ? 'tạm khóa' : 'cấm'} tài khoản của{' '}
                  <strong>{selectedUser?.fullName}</strong>?
                </p>

                <div className="form-group">
                  <label>Lý do *</label>
                  <textarea
                    value={actionReason}
                    onChange={(e) => setActionReason(e.target.value)}
                    placeholder="Nhập lý do..."
                    rows="4"
                    required
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button className="btn btn-secondary" onClick={() => setShowActionModal(false)}>
                  Hủy
                </button>
                <button
                  className={`btn ${actionType === 'ACTIVE' ? 'btn-success' : 'btn-danger'}`}
                  onClick={handleAction}
                  disabled={actionLoading}
                >
                  {actionLoading ? 'Đang xử lý...' : 'Xác nhận'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* User Detail Modal */}
        {selectedUser && !showActionModal && (
          <div className="modal-overlay" onClick={() => setSelectedUser(null)}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2>Chi tiết người dùng</h2>
                <button className="close-btn" onClick={() => setSelectedUser(null)}>×</button>
              </div>

              <div className="modal-body user-detail">
                <div className="user-detail-header">
                  <img
                    src={avatarUrls[selectedUser.userId] || 'https://ui-avatars.com/api/?name=' + encodeURIComponent(selectedUser.fullName) + '&background=0D8ABC&color=fff'}
                    alt={selectedUser.fullName}
                    className="user-detail-avatar"
                    onError={(e) => {
                      e.target.onerror = null;
                      e.target.src = 'https://ui-avatars.com/api/?name=' + encodeURIComponent(selectedUser.fullName) + '&background=0D8ABC&color=fff';
                    }}
                  />
                  <div>
                    <h3>{selectedUser.fullName}</h3>
                    <p>@{selectedUser.username}</p>
                  </div>
                </div>

                <div className="user-detail-info">
                  <div className="info-row">
                    <span className="info-label">Email:</span>
                    <span>{selectedUser.email}</span>
                  </div>
                  <div className="info-row">
                    <span className="info-label">Số điện thoại:</span>
                    <span>{selectedUser.phoneNumber}</span>
                  </div>
                  <div className="info-row">
                    <span className="info-label">Trạng thái:</span>
                    <span className={`badge ${getStatusBadgeClass(selectedUser.accountStatus)}`}>
                      {getStatusText(selectedUser.accountStatus)}
                    </span>
                  </div>
                  <div className="info-row">
                    <span className="info-label">Gói:</span>
                    <span className={`badge ${selectedUser.subscriptionStatus === 'GOLD' ? 'badge-warning' : 'badge-secondary'}`}>
                      {getStatusText(selectedUser.subscriptionStatus)}
                    </span>
                  </div>
                  <div className="info-row">
                    <span className="info-label">Ngày tạo:</span>
                    <span>{formatDate(selectedUser.createdAt)}</span>
                  </div>
                  <div className="info-row">
                    <span className="info-label">Cập nhật:</span>
                    <span>{formatDate(selectedUser.updatedAt)}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </>
  );
};

export default UserManagement;

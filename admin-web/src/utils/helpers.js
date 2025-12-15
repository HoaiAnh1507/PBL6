export const formatDate = (dateString) => {
  if (!dateString) return 'N/A';
  const date = new Date(dateString);
  return new Intl.DateTimeFormat('vi-VN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
};

export const formatNumber = (num) => {
  if (num === undefined || num === null) return '0';
  return new Intl.NumberFormat('vi-VN').format(num);
};

export const getStatusBadgeClass = (status) => {
  const statusMap = {
    ACTIVE: 'badge-success',
    SUSPENDED: 'badge-warning',
    BANNED: 'badge-danger',
    PENDING: 'badge-warning',
    RESOLVED: 'badge-success',
    DISMISSED: 'badge-secondary',
    COMPLETED: 'badge-success',
    FAILED: 'badge-danger',
  };
  return statusMap[status] || 'badge-secondary';
};

export const getStatusText = (status) => {
  const statusTextMap = {
    ACTIVE: 'Hoạt động',
    SUSPENDED: 'Tạm khóa',
    BANNED: 'Cấm vĩnh viễn',
    PENDING: 'Chờ xử lý',
    RESOLVED: 'Đã xử lý',
    DISMISSED: 'Đã bỏ qua',
    COMPLETED: 'Hoàn thành',
    FAILED: 'Thất bại',
    FREE: 'Miễn phí',
    GOLD: 'Gold',
  };
  return statusTextMap[status] || status;
};

export const truncateText = (text, maxLength = 100) => {
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
};

export const debounce = (func, wait) => {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
};

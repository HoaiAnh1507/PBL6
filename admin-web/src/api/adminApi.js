import api from './axios';

// Admin Authentication
export const adminLogin = async (email, password) => {
  const response = await api.post('/admin/auth/login', { email, password });
  return response.data;
};

export const adminLogout = async () => {
  const response = await api.post('/admin/auth/logout');
  return response.data;
};

export const getAdminProfile = async () => {
  const response = await api.get('/admin/auth/me');
  return response.data;
};

// Dashboard Metrics
export const getMetricsOverview = async () => {
  const response = await api.get('/admin/metrics/overview');
  return response.data;
};

export const getUserMetrics = async (period = '7d') => {
  const response = await api.get(`/admin/metrics/users?period=${period}`);
  return response.data;
};

export const getPostMetrics = async (period = '7d') => {
  const response = await api.get(`/admin/metrics/posts?period=${period}`);
  return response.data;
};

export const getAIPerformanceMetrics = async () => {
  const response = await api.get('/admin/metrics/ai-performance');
  return response.data;
};

// User Management
export const getUsers = async (params = {}) => {
  const response = await api.get('/admin/users', { params });
  return response.data;
};

export const getUserById = async (userId) => {
  const response = await api.get(`/admin/users/${userId}`);
  return response.data;
};

export const updateUserStatus = async (userId, status, reason) => {
  const response = await api.patch(`/admin/users/${userId}/status`, { status, reason });
  return response.data;
};

export const getUserStats = async () => {
  const response = await api.get('/admin/users/stats');
  return response.data;
};

// Reports Management
export const getReports = async (params = {}) => {
  const response = await api.get('/admin/reports', { params });
  return response.data;
};

export const getReportById = async (reportId) => {
  const response = await api.get(`/admin/reports/${reportId}`);
  return response.data;
};

export const resolveReport = async (reportId, action, resolutionNotes) => {
  const response = await api.patch(`/admin/reports/${reportId}/resolve`, {
    action,
    resolutionNotes,
  });
  return response.data;
};

// Post Management
export const getPosts = async (params = {}) => {
  const response = await api.get('/admin/posts', { params });
  return response.data;
};

export const getPostById = async (postId) => {
  const response = await api.get(`/admin/posts/${postId}`);
  return response.data;
};

export const deletePost = async (postId, reason) => {
  const response = await api.delete(`/admin/posts/${postId}`, { data: { reason } });
  return response.data;
};

export const getPostStats = async () => {
  const response = await api.get('/admin/posts/stats');
  return response.data;
};

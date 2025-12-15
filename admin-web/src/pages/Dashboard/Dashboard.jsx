import { useState, useEffect } from 'react';
import { Users, FileText, AlertTriangle, TrendingUp } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import Navbar from '../../components/Navbar';
import StatCard from '../../components/StatCard';
import { getMetricsOverview, getUserMetrics, getPostMetrics } from '../../api/adminApi';
import { formatNumber } from '../../utils/helpers';
import './Dashboard.css';

const Dashboard = () => {
  const [overview, setOverview] = useState(null);
  const [userMetrics, setUserMetrics] = useState([]);
  const [postMetrics, setPostMetrics] = useState([]);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState('7d');

  useEffect(() => {
    loadDashboardData();
  }, [period]);

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      const [overviewData, userData, postData] = await Promise.all([
        getMetricsOverview(),
        getUserMetrics(period),
        getPostMetrics(period),
      ]);
      setOverview(overviewData);
      setUserMetrics(userData);
      setPostMetrics(postData);
    } catch (error) {
      console.error('Error loading dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <>
        <Navbar />
        <div className="container">
          <div className="loading">Đang tải dữ liệu...</div>
        </div>
      </>
    );
  }

  return (
    <>
      <Navbar />
      <div className="container dashboard">
        <div className="dashboard-header">
          <h1>Dashboard</h1>
          <div className="period-selector">
            <button
              className={`btn ${period === '7d' ? 'btn-primary' : 'btn-secondary'}`}
              onClick={() => setPeriod('7d')}
            >
              7 ngày
            </button>
            <button
              className={`btn ${period === '30d' ? 'btn-primary' : 'btn-secondary'}`}
              onClick={() => setPeriod('30d')}
            >
              30 ngày
            </button>
            <button
              className={`btn ${period === '90d' ? 'btn-primary' : 'btn-secondary'}`}
              onClick={() => setPeriod('90d')}
            >
              90 ngày
            </button>
          </div>
        </div>

        <div className="stats-grid">
          <StatCard
            title="Tổng người dùng"
            value={formatNumber(overview?.totalUsers || 0)}
            icon={Users}
            color="primary"
            trend={overview?.userTrend}
          />
          <StatCard
            title="Người dùng hoạt động"
            value={formatNumber(overview?.activeUsers || 0)}
            icon={TrendingUp}
            color="success"
          />
          <StatCard
            title="Tổng bài viết"
            value={formatNumber(overview?.totalPosts || 0)}
            icon={FileText}
            color="warning"
          />
          <StatCard
            title="Báo cáo chờ xử lý"
            value={formatNumber(overview?.pendingReports || 0)}
            icon={AlertTriangle}
            color="danger"
          />
        </div>

        <div className="charts-grid">
          <div className="card">
            <h2>Tăng trưởng người dùng</h2>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={userMetrics}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="count" stroke="#007bff" name="Người dùng mới" />
              </LineChart>
            </ResponsiveContainer>
          </div>

          <div className="card">
            <h2>Hoạt động bài viết</h2>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={postMetrics}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="count" stroke="#28a745" name="Bài viết mới" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {overview?.aiPerformance && (
          <div className="card">
            <h2>Hiệu suất AI Captioning</h2>
            <div className="ai-stats">
              <div className="ai-stat-item">
                <span className="ai-stat-label">Tổng số xử lý:</span>
                <span className="ai-stat-value">{formatNumber(overview.aiPerformance.total)}</span>
              </div>
              <div className="ai-stat-item">
                <span className="ai-stat-label">Thành công:</span>
                <span className="ai-stat-value success">
                  {formatNumber(overview.aiPerformance.success)} ({overview.aiPerformance.successRate}%)
                </span>
              </div>
              <div className="ai-stat-item">
                <span className="ai-stat-label">Thất bại:</span>
                <span className="ai-stat-value danger">
                  {formatNumber(overview.aiPerformance.failed)}
                </span>
              </div>
            </div>
          </div>
        )}
      </div>
    </>
  );
};

export default Dashboard;

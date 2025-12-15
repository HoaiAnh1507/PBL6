import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { 
  LayoutDashboard, 
  Users, 
  AlertTriangle, 
  FileText, 
  LogOut 
} from 'lucide-react';
import './Navbar.css';

const Navbar = () => {
  const { admin, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = async () => {
    await logout();
    navigate('/admin/login');
  };

  const navItems = [
    { path: '/admin/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
    { path: '/admin/users', icon: Users, label: 'Người dùng' },
    { path: '/admin/reports', icon: AlertTriangle, label: 'Báo cáo' },
    { path: '/admin/posts', icon: FileText, label: 'Bài viết' },
  ];

  return (
    <nav className="navbar">
      <div className="navbar-container">
        <Link to="/admin/dashboard" className="navbar-brand">
          <h2>LocketAI Admin</h2>
        </Link>
        
        <div className="navbar-menu">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`nav-item ${isActive ? 'active' : ''}`}
              >
                <Icon size={20} />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </div>

        <div className="navbar-user">
          <span className="user-name">{admin?.fullName || admin?.email}</span>
          <button onClick={handleLogout} className="btn-logout">
            <LogOut size={20} />
            <span>Đăng xuất</span>
          </button>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;

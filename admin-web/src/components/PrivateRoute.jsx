import { Navigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const PrivateRoute = ({ children }) => {
  const { admin, loading } = useAuth();

  if (loading) {
    return (
      <div className="loading">
        <p>Đang tải...</p>
      </div>
    );
  }

  return admin ? children : <Navigate to="/admin/login" replace />;
};

export default PrivateRoute;

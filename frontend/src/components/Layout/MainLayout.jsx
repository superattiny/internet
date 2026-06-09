// ================================================
// MainLayout.jsx — Asosiy sahifa tuzilishi
// Sidebar + Header + sahifa kontenti
// ================================================

import { useEffect } from 'react';
import { useLocation, Navigate } from 'react-router-dom';
import useAuthStore from '@/store/authStore';
import useOrderStore from '@/store/orderStore';
import { usePolling } from '@/utils/hooks';
import Sidebar from './Sidebar';
import Header  from './Header';

export default function MainLayout({ children }) {
  const location  = useLocation();
  const { isLoggedIn } = useAuthStore();
  const { fetchDeadlineAlerts, fetchStats } = useOrderStore();

  // Tizimga kirmagan bo'lsa login sahifasiga yo'naltir
  if (!isLoggedIn) {
    return <Navigate to="/login" replace />;
  }

  // Deadline alertlarni har 60 sekundda avtomatik yangilash
  usePolling(fetchDeadlineAlerts, 60_000, true);

  // Statistikani yuklash (sahifa o'zgarganda)
  useEffect(() => {
    fetchStats();
  }, [location.pathname]);

  return (
    <div className="app-layout">
      <Sidebar />
      <div className="main-content">
        <Header pathname={location.pathname} />
        <main className="page-content animate-fade-in">
          {children}
        </main>
      </div>
    </div>
  );
}

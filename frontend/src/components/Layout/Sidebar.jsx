// ================================================
// Sidebar.jsx — Chap panel navigatsiya
// ================================================

import { NavLink, useNavigate } from 'react-router-dom';
import useAuthStore from '@/store/authStore';
import { getInitials, ROLE_LABELS } from '@/utils/formatters';
import useOrderStore from '@/store/orderStore';

// Nav elementlari konfiguratsiyasi
const NAV_ITEMS = [
  {
    section: 'Asosiy',
    items: [
      { to: '/dashboard', icon: '📊', label: 'Dashboard' },
      { to: '/orders',    icon: '📋', label: 'Zakazlar',  badgeKey: 'overdueCount' },
    ],
  },
  {
    section: 'Boshqaruv',
    items: [
      { to: '/workers',   icon: '👷', label: 'Ishchilar',  adminOnly: true },
      { to: '/clients',   icon: '👥', label: 'Mijozlar' },
      { to: '/warehouse', icon: '🏪', label: 'Ombor',      adminOnly: true },
      { to: '/finance',   icon: '💰', label: 'Moliya',     adminOnly: true },
    ],
  },
  {
    section: 'Arxiv',
    items: [
      { to: '/archive',   icon: '📦', label: 'Arxiv' },
    ],
  },
];

export default function Sidebar() {
  const navigate    = useNavigate();
  const { user, logout, isAdmin } = useAuthStore();
  const { overdueCount } = useOrderStore();

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const roleLabel = ROLE_LABELS[user?.role] || user?.role;
  const initials  = getInitials(user?.full_name);

  return (
    <aside className="sidebar">
      {/* Logo */}
      <div className="sidebar-logo">
        <div className="sidebar-logo-icon">📺</div>
        <div className="sidebar-logo-text">
          <div className="sidebar-logo-title">TV CRM</div>
          <div className="sidebar-logo-sub">Boshqaruv tizimi</div>
        </div>
      </div>

      {/* Navigatsiya */}
      <nav className="sidebar-nav">
        {NAV_ITEMS.map((section) => {
          // Admin-only elementlarni filtr
          const visibleItems = section.items.filter(
            (item) => !item.adminOnly || isAdmin()
          );
          if (!visibleItems.length) return null;

          return (
            <div key={section.section}>
              <div className="nav-section-label">{section.section}</div>
              {visibleItems.map((item) => {
                const badge = item.badgeKey === 'overdueCount' ? overdueCount : 0;
                return (
                  <NavLink
                    key={item.to}
                    to={item.to}
                    className={({ isActive }) =>
                      `nav-item${isActive ? ' active' : ''}`
                    }
                  >
                    <span className="nav-icon">{item.icon}</span>
                    <span style={{ flex: 1 }}>{item.label}</span>
                    {badge > 0 && (
                      <span className="nav-badge">{badge > 99 ? '99+' : badge}</span>
                    )}
                  </NavLink>
                );
              })}
            </div>
          );
        })}
      </nav>

      {/* Footer — foydalanuvchi */}
      <div className="sidebar-footer">
        <div className="sidebar-user" onClick={handleLogout} title="Tizimdan chiqish">
          <div className="sidebar-avatar">{initials}</div>
          <div className="sidebar-user-info">
            <div className="sidebar-user-name">{user?.full_name || 'Foydalanuvchi'}</div>
            <div className="sidebar-user-role">{roleLabel} · Chiqish</div>
          </div>
          <span style={{ color: '#475569', fontSize: 14 }}>→</span>
        </div>
      </div>
    </aside>
  );
}

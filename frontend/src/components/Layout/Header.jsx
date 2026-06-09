// ================================================
// Header.jsx — Yuqori panel
// Sahifa sarlavhasi, qidiruv, bildirishnomalar
// ================================================

import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import useAuthStore from '@/store/authStore';
import useOrderStore from '@/store/orderStore';
import { useClickOutside } from '@/utils/hooks';
import { formatMoney } from '@/utils/formatters';

// Sahifa sarlavhalari
const PAGE_TITLES = {
  '/dashboard': { title: 'Dashboard',   icon: '📊' },
  '/orders':    { title: 'Zakazlar',    icon: '📋' },
  '/workers':   { title: 'Ishchilar',   icon: '👷' },
  '/clients':   { title: 'Mijozlar',    icon: '👥' },
  '/warehouse': { title: 'Ombor',       icon: '🏪' },
  '/finance':   { title: 'Moliya',      icon: '💰' },
  '/archive':   { title: 'Arxiv',       icon: '📦' },
};

export default function Header({ pathname }) {
  const navigate  = useNavigate();
  const { user, logout, isAdmin } = useAuthStore();
  const { overdueCount, deadlineAlerts } = useOrderStore();

  const [showNotif,   setShowNotif]   = useState(false);
  const [showProfile, setShowProfile] = useState(false);

  const notifRef   = useClickOutside(() => setShowNotif(false));
  const profileRef = useClickOutside(() => setShowProfile(false));

  const pageInfo = PAGE_TITLES[pathname] || { title: 'Sahifa', icon: '📄' };

  const handleLogout = useCallback(async () => {
    await logout();
    navigate('/login');
  }, [logout, navigate]);

  return (
    <header className="header">
      {/* Chap: sahifa nomi */}
      <div className="header-left">
        <span style={{ fontSize: 20 }}>{pageInfo.icon}</span>
        <h1 className="header-title">{pageInfo.title}</h1>

        {/* Overdue badge */}
        {overdueCount > 0 && (
          <span
            className="badge deadline-overdue"
            style={{ cursor: 'pointer' }}
            onClick={() => navigate('/orders?only_overdue=true')}
          >
            🔴 {overdueCount} ta muddati o'tgan
          </span>
        )}
      </div>

      {/* O'ng: amallar */}
      <div className="header-right">

        {/* Balans (faqat admin) */}
        {isAdmin() && user?.balance !== undefined && (
          <div
            style={{
              padding: '6px 14px',
              background: '#f0fdf4',
              border: '1px solid #bbf7d0',
              borderRadius: 20,
              fontSize: 13,
              fontWeight: 600,
              color: '#16a34a',
              cursor: 'pointer',
            }}
            onClick={() => navigate('/finance')}
            title="Moliya sahifasiga o'tish"
          >
            💰 {formatMoney(user.balance)}
          </div>
        )}

        {/* Bildirishnomalar */}
        <div ref={notifRef} className="dropdown">
          <button
            className="btn btn-ghost btn-icon"
            style={{ position: 'relative' }}
            onClick={() => { setShowNotif((p) => !p); setShowProfile(false); }}
            title="Bildirishnomalar"
          >
            🔔
            {overdueCount > 0 && (
              <span
                style={{
                  position: 'absolute', top: 4, right: 4,
                  width: 8, height: 8,
                  background: '#dc2626', borderRadius: '50%',
                  border: '1.5px solid white',
                }}
              />
            )}
          </button>

          {showNotif && (
            <div className="dropdown-menu" style={{ width: 320 }}>
              <div style={{ padding: '12px 14px 8px', borderBottom: '1px solid #f1f5f9' }}>
                <span style={{ fontWeight: 700, fontSize: 14 }}>
                  Bildirishnomalar
                </span>
                {overdueCount > 0 && (
                  <span
                    className="badge deadline-overdue"
                    style={{ marginLeft: 8, fontSize: 11 }}
                  >
                    {overdueCount} ta
                  </span>
                )}
              </div>

              <div style={{ maxHeight: 280, overflowY: 'auto' }}>
                {deadlineAlerts.length === 0 ? (
                  <div style={{ padding: '20px 14px', textAlign: 'center', color: '#94a3b8', fontSize: 13 }}>
                    Bildirishnomalar yo'q ✅
                  </div>
                ) : (
                  deadlineAlerts.slice(0, 8).map((alert) => (
                    <div
                      key={alert.order_id}
                      className="dropdown-item"
                      style={{ flexDirection: 'column', alignItems: 'flex-start', gap: 2 }}
                      onClick={() => {
                        navigate(`/orders`);
                        setShowNotif(false);
                      }}
                    >
                      <div style={{ fontWeight: 600, fontSize: 13 }}>
                        {alert.is_overdue ? '❌' : '⚠️'} {alert.order_number}
                      </div>
                      <div style={{ fontSize: 12, color: '#64748b' }}>
                        {alert.client_name} · {alert.tv_info}
                      </div>
                      <div
                        style={{
                          fontSize: 11,
                          color: alert.is_overdue ? '#dc2626' : '#d97706',
                          fontWeight: 600,
                        }}
                      >
                        {alert.is_overdue
                          ? `${Math.abs(alert.hours_remaining).toFixed(0)} soat oldin o'tdi`
                          : `${alert.hours_remaining.toFixed(0)} soat qoldi`}
                      </div>
                    </div>
                  ))
                )}
              </div>

              {deadlineAlerts.length > 0 && (
                <div
                  style={{
                    padding: '10px 14px',
                    borderTop: '1px solid #f1f5f9',
                    textAlign: 'center',
                  }}
                >
                  <button
                    className="btn btn-ghost btn-sm"
                    style={{ width: '100%', justifyContent: 'center' }}
                    onClick={() => { navigate('/orders?only_overdue=true'); setShowNotif(false); }}
                  >
                    Barchasini ko'rish →
                  </button>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Profil */}
        <div ref={profileRef} className="dropdown">
          <button
            className="btn btn-ghost"
            style={{ padding: '4px 8px', gap: 8 }}
            onClick={() => { setShowProfile((p) => !p); setShowNotif(false); }}
          >
            <div
              style={{
                width: 30, height: 30, borderRadius: '50%',
                background: '#2563eb', color: 'white',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 12, fontWeight: 700,
              }}
            >
              {user?.full_name?.[0]?.toUpperCase() || 'U'}
            </div>
            <span style={{ fontSize: 13, fontWeight: 600, color: '#374151' }}>
              {user?.full_name?.split(' ')[0] || 'Foydalanuvchi'}
            </span>
            <span style={{ fontSize: 11, color: '#94a3b8' }}>▾</span>
          </button>

          {showProfile && (
            <div className="dropdown-menu">
              <div
                style={{
                  padding: '10px 14px 8px',
                  borderBottom: '1px solid #f1f5f9',
                }}
              >
                <div style={{ fontWeight: 600, fontSize: 13 }}>{user?.full_name}</div>
                <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 2 }}>
                  @{user?.username} · {user?.role}
                </div>
              </div>
              <div
                className="dropdown-item"
                onClick={() => { navigate('/dashboard'); setShowProfile(false); }}
              >
                📊 Dashboard
              </div>
              <div className="dropdown-divider" />
              <div className="dropdown-item danger" onClick={handleLogout}>
                🚪 Tizimdan chiqish
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}

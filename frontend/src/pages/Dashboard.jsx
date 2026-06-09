// ================================================
// Dashboard.jsx — Bosh sahifa
// Stat kartalar, deadline signal, ustalar jadvali
// ================================================

import { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import useAuthStore  from '@/store/authStore';
import useOrderStore from '@/store/orderStore';
import workersApi    from '@/api/workersApi';
import ordersApi     from '@/api/ordersApi';
import {
  formatMoney, formatDate, formatDeadline,
  ORDER_STATUS_LABELS, ORDER_STATUS_COLORS, ORDER_STATUS_ICONS,
  ROLE_LABELS, formatTvInfo, getInitials,
} from '@/utils/formatters';
import { usePageTitle, usePolling } from '@/utils/hooks';

// ================================================================
//  KICHIK KOMPONENTLAR
// ================================================================

function StatCard({ icon, iconBg, label, value, sub, onClick }) {
  return (
    <div className="stat-card" style={{ cursor: onClick ? 'pointer' : 'default' }} onClick={onClick}>
      <div className={`stat-icon ${iconBg}`}>{icon}</div>
      <div className="stat-body">
        <div className="stat-label">{label}</div>
        <div className="stat-value">{value ?? '—'}</div>
        {sub && <div className="stat-sub">{sub}</div>}
      </div>
    </div>
  );
}

function SectionHeader({ title, action, actionLabel }) {
  return (
    <div className="card-header" style={{ marginBottom: 0 }}>
      <h2 className="card-title">{title}</h2>
      {action && (
        <button className="btn btn-ghost btn-sm" onClick={action}>
          {actionLabel} →
        </button>
      )}
    </div>
  );
}

// ── Deadline alert qatori ──────────────────────────────────────
function AlertRow({ alert, onClick }) {
  const { label, className, icon } = formatDeadline(alert.deadline, alert.hours_remaining);
  return (
    <div
      onClick={onClick}
      style={{
        display: 'flex', alignItems: 'center', gap: 12,
        padding: '11px 20px', borderBottom: '1px solid #f8fafc',
        cursor: 'pointer', transition: 'background 0.15s',
      }}
      onMouseEnter={(e) => e.currentTarget.style.background = '#fafafa'}
      onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
    >
      {/* Puls indikator */}
      <div style={{ position: 'relative', width: 10, height: 10, flexShrink: 0 }}>
        <div style={{
          width: 10, height: 10, borderRadius: '50%',
          background: alert.is_overdue ? '#dc2626' : '#d97706',
          position: 'absolute',
        }} />
        {alert.is_overdue && (
          <div style={{
            width: 10, height: 10, borderRadius: '50%',
            background: '#dc2626', opacity: 0.4,
            position: 'absolute', animation: 'ping 1.5s infinite',
            transform: 'scale(1)',
          }} />
        )}
      </div>

      {/* Asosiy ma'lumot */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
          <span style={{ fontWeight: 700, fontSize: 13, color: '#0f172a' }}>
            {alert.order_number}
          </span>
          <span className={`badge ${className}`} style={{ fontSize: 11 }}>
            {icon} {label}
          </span>
        </div>
        <div style={{ fontSize: 12, color: '#64748b', marginTop: 2 }}>
          {alert.client_name}
          {alert.tv_info && alert.tv_info !== "TV ma'lumoti yo'q"
            ? ` · ${alert.tv_info}` : ''}
        </div>
      </div>

      {/* Usta */}
      {alert.master_name && (
        <div style={{
          fontSize: 12, color: '#64748b',
          background: '#f1f5f9', padding: '3px 8px', borderRadius: 12,
          flexShrink: 0,
        }}>
          👷 {alert.master_name}
        </div>
      )}
    </div>
  );
}

// ── Zakaz holati kartasi ───────────────────────────────────────
function OrderStatusCard({ status, count, onClick }) {
  return (
    <div
      onClick={onClick}
      style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '10px 12px',
        background: '#fafafa', borderRadius: 8,
        border: '1px solid #f1f5f9',
        cursor: 'pointer', transition: 'all 0.15s',
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.background = '#f1f5f9';
        e.currentTarget.style.borderColor = '#e2e8f0';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.background = '#fafafa';
        e.currentTarget.style.borderColor = '#f1f5f9';
      }}
    >
      <span style={{ fontSize: 18 }}>{ORDER_STATUS_ICONS[status]}</span>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 12, color: '#64748b' }}>{ORDER_STATUS_LABELS[status]}</div>
        <div style={{ fontSize: 20, fontWeight: 800, color: '#0f172a', lineHeight: 1.1 }}>
          {count}
        </div>
      </div>
    </div>
  );
}

// ── Usta qatori ────────────────────────────────────────────────
function WorkerRow({ worker, onClick }) {
  const initials = getInitials(worker.full_name);
  return (
    <tr
      style={{ cursor: 'pointer' }}
      onClick={onClick}
    >
      <td>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 32, height: 32, borderRadius: '50%',
            background: '#2563eb', color: 'white',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 12, fontWeight: 700, flexShrink: 0,
          }}>
            {initials}
          </div>
          <div>
            <div style={{ fontWeight: 600, fontSize: 13 }}>{worker.full_name}</div>
            <div style={{ fontSize: 11, color: '#94a3b8' }}>@{worker.username}</div>
          </div>
        </div>
      </td>
      <td>
        <span className={`badge badge-${worker.role}`}>
          {ROLE_LABELS[worker.role] || worker.role}
        </span>
      </td>
      <td style={{ fontWeight: 700, color: '#16a34a' }}>
        {formatMoney(worker.balance)}
      </td>
      <td>
        <span style={{ fontWeight: 600, color: '#0f172a' }}>
          {worker.total_orders_done ?? 0}
        </span>
        <span style={{ color: '#94a3b8', fontSize: 12 }}> ta</span>
      </td>
      <td>
        <span style={{
          display: 'inline-flex', alignItems: 'center', gap: 4,
          fontSize: 12, fontWeight: 600,
          color: worker.commission_percent > 0 ? '#2563eb' : '#94a3b8',
        }}>
          {worker.commission_percent > 0
            ? `${worker.commission_percent}%`
            : '—'}
        </span>
      </td>
      <td>
        <span className={`badge ${worker.is_active ? 'badge-accepted' : 'badge-cancelled'}`}>
          {worker.is_active ? '✅ Faol' : '🔒 Bloklangan'}
        </span>
      </td>
    </tr>
  );
}

// ── Oxirgi zakazlar qatori ─────────────────────────────────────
function RecentOrderRow({ order, onClick }) {
  const { label, className } = formatDeadline(order.deadline, order.hours_until_deadline);
  return (
    <tr onClick={onClick} style={{ cursor: 'pointer' }}>
      <td>
        <span style={{ fontFamily: 'monospace', fontWeight: 700, color: '#2563eb' }}>
          {order.order_number}
        </span>
      </td>
      <td>
        <div style={{ fontWeight: 600, fontSize: 13 }}>{order.client?.full_name}</div>
        <div style={{ fontSize: 11, color: '#94a3b8' }}>{order.client?.phone || '—'}</div>
      </td>
      <td style={{ maxWidth: 180 }}>
        <div style={{ fontSize: 12, color: '#374151', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {formatTvInfo(order)}
        </div>
      </td>
      <td>
        <span className={`badge ${ORDER_STATUS_COLORS[order.status]}`}>
          {ORDER_STATUS_ICONS[order.status]} {ORDER_STATUS_LABELS[order.status]}
        </span>
      </td>
      <td>
        <span className={`badge ${className}`} style={{ fontSize: 11 }}>
          {label}
        </span>
      </td>
      <td style={{ fontSize: 12, color: '#64748b' }}>
        {order.master?.full_name || <span style={{ color: '#cbd5e1' }}>Tayinlanmagan</span>}
      </td>
    </tr>
  );
}

// ================================================================
//  ASOSIY KOMPONENT
// ================================================================

export default function Dashboard() {
  usePageTitle('Dashboard');
  const navigate   = useNavigate();
  const { user, isAdmin } = useAuthStore();
  const { stats, deadlineAlerts, fetchStats, fetchDeadlineAlerts } = useOrderStore();

  const [workers,      setWorkers]      = useState([]);
  const [recentOrders, setRecentOrders] = useState([]);
  const [statusCounts, setStatusCounts] = useState({});
  const [loading,      setLoading]      = useState(true);

  // ── Ma'lumotlarni yuklash ──────────────────────────────────
  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [workersRes, ordersRes] = await Promise.all([
        workersApi.getList({ is_active: true, page_size: 10 }),
        ordersApi.getList({ page: 1, page_size: 8, is_archived: false }),
      ]);
      setWorkers(workersRes.items || []);
      setRecentOrders(ordersRes.items || []);

      // Status bo'yicha hisoblash
      const counts = {};
      (ordersRes.items || []).forEach((o) => {
        counts[o.status] = (counts[o.status] || 0) + 1;
      });
      setStatusCounts(counts);
    } catch (err) {
      console.error('Dashboard yuklash xatosi:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
    fetchStats();
    fetchDeadlineAlerts();
  }, []);

  // Har 60 sekundda yangilash
  usePolling(fetchDeadlineAlerts, 60_000, true);
  usePolling(fetchStats,          60_000, true);

  // ── Yuklanish holati ──────────────────────────────────────
  if (loading && !stats) {
    return (
      <div className="page-loader">
        <div className="spinner" />
        <span>Dashboard yuklanmoqda...</span>
      </div>
    );
  }

  const overdueAlerts  = deadlineAlerts.filter((a) => a.is_overdue);
  const warningAlerts  = deadlineAlerts.filter((a) => !a.is_overdue);

  return (
    <div>
      {/* ── Overdue Banner ────────────────────────────────────── */}
      {overdueAlerts.length > 0 && (
        <div
          className="overdue-banner"
          style={{ marginBottom: 20, cursor: 'pointer' }}
          onClick={() => navigate('/orders?only_overdue=true')}
        >
          <div className="overdue-banner-pulse" />
          <div style={{ flex: 1 }}>
            <span style={{ fontWeight: 700 }}>
              ❌ {overdueAlerts.length} ta zakazning muddati o'tib ketdi!
            </span>
            <span style={{ fontSize: 13, marginLeft: 8, opacity: 0.8 }}>
              Darhol ko'rish uchun bosing
            </span>
          </div>
          <span style={{ fontWeight: 600, fontSize: 13 }}>→</span>
        </div>
      )}

      {/* ── Stat kartalar ─────────────────────────────────────── */}
      <div className="stats-grid">
        <StatCard
          icon="📋" iconBg="blue"
          label="Jami faol zakazlar"
          value={stats?.total_orders ?? 0}
          sub="Arxivlanmaganlar"
          onClick={() => navigate('/orders')}
        />
        <StatCard
          icon="🆕" iconBg="cyan"
          label="Yangi zakazlar"
          value={stats?.new_orders ?? 0}
          sub="Kutmoqda"
          onClick={() => navigate('/orders?status=new')}
        />
        <StatCard
          icon="🔧" iconBg="yellow"
          label="Jarayonda"
          value={stats?.in_progress ?? 0}
          sub="Qabul, diagnostika, ta'mir"
          onClick={() => navigate('/orders')}
        />
        <StatCard
          icon="🎉" iconBg="green"
          label="Bugun topshirildi"
          value={stats?.delivered_today ?? 0}
          sub={`Daromad: ${formatMoney(stats?.total_revenue_today ?? 0)}`}
        />
        <StatCard
          icon="⚠️" iconBg="red"
          label="Muddati o'tgan"
          value={stats?.overdue_count ?? 0}
          sub="Shoshilish kerak"
          onClick={() => navigate('/orders?only_overdue=true')}
        />
        <StatCard
          icon="💰" iconBg="green"
          label="Bugungi daromad"
          value={formatMoney(stats?.total_revenue_today ?? 0)}
          sub="Topshirilgan zakazlar"
          onClick={() => navigate('/finance')}
        />
      </div>

      {/* ── Asosiy grid ───────────────────────────────────────── */}
      <div className="dashboard-grid">

        {/* ── Deadline alertlar ─────────────────────────────── */}
        <div className="card">
          <SectionHeader
            title={`⏰ Deadline nazorat ${deadlineAlerts.length > 0 ? `(${deadlineAlerts.length})` : ''}`}
            action={() => navigate('/orders?only_overdue=true')}
            actionLabel="Barchasi"
          />
          <div style={{ marginTop: 4 }}>
            {deadlineAlerts.length === 0 ? (
              <div className="empty-state" style={{ padding: '40px 20px' }}>
                <div className="empty-icon">✅</div>
                <div className="empty-title">Barcha zakazlar vaqtida!</div>
                <div className="empty-text">Muddati o'tayotgan zakazlar yo'q</div>
              </div>
            ) : (
              <>
                {overdueAlerts.slice(0, 4).map((a) => (
                  <AlertRow
                    key={a.order_id}
                    alert={a}
                    onClick={() => navigate('/orders')}
                  />
                ))}
                {warningAlerts.slice(0, 3).map((a) => (
                  <AlertRow
                    key={a.order_id}
                    alert={a}
                    onClick={() => navigate('/orders')}
                  />
                ))}
                {deadlineAlerts.length > 7 && (
                  <div
                    style={{
                      padding: '10px 20px', textAlign: 'center',
                      fontSize: 13, color: '#64748b', borderTop: '1px solid #f8fafc',
                      cursor: 'pointer',
                    }}
                    onClick={() => navigate('/orders?only_overdue=true')}
                  >
                    + {deadlineAlerts.length - 7} ta ko'proq →
                  </div>
                )}
              </>
            )}
          </div>
        </div>

        {/* ── Holat bo'yicha statistika ──────────────────────── */}
        <div className="card">
          <SectionHeader
            title="📊 Zakazlar holati"
            action={() => navigate('/orders')}
            actionLabel="Barchasi"
          />
          <div className="card-body">
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              {['new','accepted','diagnosing','waiting',
                'on_the_way','in_repair','done','delivered'].map((status) => (
                <OrderStatusCard
                  key={status}
                  status={status}
                  count={
                    status === 'new'       ? (stats?.new_orders      ?? 0) :
                    status === 'delivered' ? (stats?.delivered_today ?? 0) :
                    (statusCounts[status]  ?? 0)
                  }
                  onClick={() => navigate(`/orders?status=${status}`)}
                />
              ))}
            </div>
          </div>
        </div>

        {/* ── Oxirgi zakazlar ───────────────────────────────── */}
        <div className="card full-width">
          <SectionHeader
            title="📋 Oxirgi zakazlar"
            action={() => navigate('/orders')}
            actionLabel="Barchasi"
          />
          <div className="table-wrapper" style={{ margin: '12px 0 0', border: 'none', borderRadius: 0 }}>
            {recentOrders.length === 0 ? (
              <div className="empty-state">
                <div className="empty-icon">📋</div>
                <div className="empty-title">Zakazlar yo'q</div>
                <div className="empty-text">Hali birorta zakaz qo'shilmagan</div>
              </div>
            ) : (
              <table className="table">
                <thead>
                  <tr>
                    <th>Raqam</th>
                    <th>Mijoz</th>
                    <th>Televizor</th>
                    <th>Holat</th>
                    <th>Deadline</th>
                    <th>Usta</th>
                  </tr>
                </thead>
                <tbody>
                  {recentOrders.map((order) => (
                    <RecentOrderRow
                      key={order.id}
                      order={order}
                      onClick={() => navigate('/orders')}
                    />
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* ── Ustalar jadvali ───────────────────────────────── */}
        {isAdmin() && (
          <div className="card full-width">
            <SectionHeader
              title="👷 Ishchilar holati"
              action={() => navigate('/workers')}
              actionLabel="Barchasi"
            />
            <div className="table-wrapper" style={{ margin: '12px 0 0', border: 'none', borderRadius: 0 }}>
              {workers.length === 0 ? (
                <div className="empty-state">
                  <div className="empty-icon">👷</div>
                  <div className="empty-title">Ishchilar yo'q</div>
                </div>
              ) : (
                <table className="table">
                  <thead>
                    <tr>
                      <th>Ishchi</th>
                      <th>Rol</th>
                      <th>Balans</th>
                      <th>Bitirgan</th>
                      <th>Komisyon</th>
                      <th>Holat</th>
                    </tr>
                  </thead>
                  <tbody>
                    {workers.map((worker) => (
                      <WorkerRow
                        key={worker.id}
                        worker={worker}
                        onClick={() => navigate('/workers')}
                      />
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        )}

      </div>{/* /dashboard-grid */}
    </div>
  );
}

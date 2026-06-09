// ================================================
// StatusBadge.jsx — Holat va deadline badge'lari
// ================================================

import {
  ORDER_STATUS_LABELS,
  ORDER_STATUS_COLORS,
  ORDER_STATUS_ICONS,
  ROLE_LABELS,
  ROLE_COLORS,
  formatDeadline,
} from '@/utils/formatters';

// ── Zakaz status badge ───────────────────────────────────────────
export function OrderStatusBadge({ status, showIcon = true }) {
  if (!status) return null;
  return (
    <span className={`badge ${ORDER_STATUS_COLORS[status] || ''}`}>
      {showIcon && ORDER_STATUS_ICONS[status]} {ORDER_STATUS_LABELS[status] || status}
    </span>
  );
}

// ── Deadline badge ───────────────────────────────────────────────
export function DeadlineBadge({ deadline, hoursRemaining, compact = false }) {
  if (!deadline) return null;
  const { label, className, icon } = formatDeadline(deadline, hoursRemaining);
  return (
    <span className={`badge ${className}`} style={{ fontSize: compact ? 11 : undefined }}>
      {!compact && `${icon} `}{label}
    </span>
  );
}

// ── Rol badge ────────────────────────────────────────────────────
export function RoleBadge({ role }) {
  if (!role) return null;
  return (
    <span className={`badge badge-${role}`}>
      {ROLE_LABELS[role] || role}
    </span>
  );
}

// ── To'lov holati badge ──────────────────────────────────────────
export function PaymentBadge({ isPaid, paymentMethod }) {
  const LABELS = { cash: 'Naqd', card: 'Karta', transfer: "O'tkazma" };
  if (isPaid) {
    return (
      <span className="badge badge-accepted">
        ✅ To'langan{paymentMethod ? ` (${LABELS[paymentMethod]})` : ''}
      </span>
    );
  }
  return <span className="badge badge-waiting">⏳ To'lanmagan</span>;
}

// ── Faollik badge ────────────────────────────────────────────────
export function ActiveBadge({ isActive }) {
  return isActive
    ? <span className="badge badge-accepted">✅ Faol</span>
    : <span className="badge badge-cancelled">🔒 Bloklangan</span>;
}

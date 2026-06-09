// ================================================
// StatusModal.jsx — Status o'zgartirish modali
// ================================================

import { useState } from 'react';
import ordersApi from '@/api/ordersApi';
import {
  getAllowedNextStatuses,
  ORDER_STATUS_LABELS,
  ORDER_STATUS_ICONS,
  ORDER_STATUS_COLORS,
  formatMoney,
  PAYMENT_METHOD_LABELS,
} from '@/utils/formatters';
import toast from 'react-hot-toast';

export default function StatusModal({ order, onClose, onUpdated }) {
  const [selected,      setSelected]      = useState('');
  const [comment,       setComment]       = useState('');
  const [saving,        setSaving]        = useState(false);
  // To'lov modali (faqat done → delivered)
  const [showPayment,   setShowPayment]   = useState(false);
  const [finalPrice,    setFinalPrice]    = useState(
    order.final_price > 0 ? String(order.final_price) : String(order.estimated_price || '')
  );
  const [payMethod,     setPayMethod]     = useState('cash');
  const [payComment,    setPayComment]    = useState('');

  const nextStatuses = getAllowedNextStatuses(order.status);

  // ── Status o'zgartirish ──────────────────────────────────────
  const handleStatusChange = async () => {
    if (!selected) { toast.error('Yangi holat tanlang'); return; }
    setSaving(true);
    try {
      // DONE → DELIVERED holati to'lov orqali amalga oshiriladi
      if (selected === 'delivered') {
        setShowPayment(true);
        setSaving(false);
        return;
      }
      const updated = await ordersApi.changeStatus(order.id, selected, comment);
      toast.success(`✅ Holat o'zgardi: ${ORDER_STATUS_LABELS[updated.status]}`);
      onUpdated?.(updated);
      onClose();
    } catch (err) {
      toast.error(err.message || 'Xato yuz berdi');
    } finally {
      setSaving(false);
    }
  };

  // ── To'lov qabul qilish ──────────────────────────────────────
  const handlePayment = async () => {
    const price = parseFloat(finalPrice);
    if (!price || price <= 0) { toast.error("To'lov summasi kiritilishi shart"); return; }
    setSaving(true);
    try {
      const updated = await ordersApi.acceptPayment(
        order.id, price, payMethod, payComment
      );
      toast.success(`💳 To'lov qabul qilindi: ${formatMoney(price)}`);
      onUpdated?.(updated);
      onClose();
    } catch (err) {
      toast.error(err.message || "To'lovda xato");
    } finally {
      setSaving(false);
    }
  };

  // ── To'lov formasi ───────────────────────────────────────────
  if (showPayment) {
    return (
      <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
        <div className="modal modal-sm">
          <div className="modal-header">
            <h2 className="modal-title">💳 To'lov qabul qilish</h2>
            <button className="modal-close" onClick={onClose}>✕</button>
          </div>
          <div className="modal-body">
            <div className="alert alert-info" style={{ marginBottom: 16 }}>
              <span className="alert-icon">ℹ️</span>
              <div className="alert-text">
                <b>{order.order_number}</b> — {order.client?.full_name}
                <br />
                <span style={{ fontSize: 12 }}>Taxminiy narx: {formatMoney(order.estimated_price)}</span>
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">
                Yakuniy summa (so'm) <span className="required">*</span>
              </label>
              <input
                className="form-input"
                type="number" min="0"
                value={finalPrice}
                onChange={(e) => setFinalPrice(e.target.value)}
                autoFocus
              />
            </div>

            <div className="form-group">
              <label className="form-label">To'lov usuli</label>
              <select
                className="form-select"
                value={payMethod}
                onChange={(e) => setPayMethod(e.target.value)}
              >
                {Object.entries(PAYMENT_METHOD_LABELS).map(([v, l]) => (
                  <option key={v} value={v}>{l}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Izoh</label>
              <input
                className="form-input"
                placeholder="Mijoz to'liq to'ladi..."
                value={payComment}
                onChange={(e) => setPayComment(e.target.value)}
              />
            </div>
          </div>
          <div className="modal-footer">
            <button className="btn btn-secondary" onClick={() => setShowPayment(false)}>
              ← Orqaga
            </button>
            <button className="btn btn-success" onClick={handlePayment} disabled={saving}>
              {saving
                ? <><span className="spinner" style={{ width: 14, height: 14 }} /> Saqlanmoqda...</>
                : '💳 To\'lovni qabul qilish'
              }
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ── Asosiy status tanlash modali ─────────────────────────────
  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal modal-sm">
        <div className="modal-header">
          <h2 className="modal-title">🔄 Holat o'zgartirish</h2>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>
        <div className="modal-body">
          {/* Joriy holat */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '10px 14px', background: '#f8fafc',
            borderRadius: 8, marginBottom: 16,
          }}>
            <span style={{ fontSize: 13, color: '#64748b' }}>Hozirgi holat:</span>
            <span className={`badge ${ORDER_STATUS_COLORS[order.status]}`}>
              {ORDER_STATUS_ICONS[order.status]} {ORDER_STATUS_LABELS[order.status]}
            </span>
          </div>

          {/* Yangi holat tanlash */}
          {nextStatuses.length === 0 ? (
            <div className="alert alert-info">
              <span className="alert-icon">ℹ️</span>
              <div className="alert-text">Bu holat yakuniy — o'zgartirib bo'lmaydi.</div>
            </div>
          ) : (
            <div className="form-group">
              <label className="form-label">
                Yangi holat <span className="required">*</span>
              </label>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {nextStatuses.map((s) => (
                  <label
                    key={s.value}
                    style={{
                      display: 'flex', alignItems: 'center', gap: 10,
                      padding: '10px 14px',
                      border: `2px solid ${selected === s.value ? '#2563eb' : '#e2e8f0'}`,
                      borderRadius: 8, cursor: 'pointer',
                      background: selected === s.value ? '#eff6ff' : 'white',
                      transition: 'all 0.15s',
                    }}
                  >
                    <input
                      type="radio"
                      name="status"
                      value={s.value}
                      checked={selected === s.value}
                      onChange={() => setSelected(s.value)}
                      style={{ accentColor: '#2563eb' }}
                    />
                    <span style={{ fontSize: 16 }}>{s.icon}</span>
                    <span style={{ fontWeight: 600, fontSize: 13 }}>{s.label}</span>
                    {s.value === 'cancelled' && (
                      <span className="badge badge-cancelled" style={{ marginLeft: 'auto', fontSize: 10 }}>
                        Arxivlanadi
                      </span>
                    )}
                    {s.value === 'delivered' && (
                      <span className="badge badge-accepted" style={{ marginLeft: 'auto', fontSize: 10 }}>
                        To'lov kerak
                      </span>
                    )}
                  </label>
                ))}
              </div>
            </div>
          )}

          {/* Izoh */}
          {nextStatuses.length > 0 && (
            <div className="form-group" style={{ marginTop: 4 }}>
              <label className="form-label">Izoh (ixtiyoriy)</label>
              <textarea
                className="form-textarea"
                rows={2}
                placeholder="Sabab yoki qo'shimcha ma'lumot..."
                value={comment}
                onChange={(e) => setComment(e.target.value)}
              />
            </div>
          )}
        </div>

        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose} disabled={saving}>
            Bekor qilish
          </button>
          {nextStatuses.length > 0 && (
            <button
              className="btn btn-primary"
              onClick={handleStatusChange}
              disabled={saving || !selected}
            >
              {saving
                ? <><span className="spinner" style={{ width: 14, height: 14 }} /> Saqlanmoqda...</>
                : '✅ Tasdiqlash'
              }
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

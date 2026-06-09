// ================================================
// OrderDetailModal.jsx — Zakaz to'liq ma'lumoti
// ================================================

import {
  formatMoney, formatDate, formatDeadline,
  ORDER_STATUS_LABELS, ORDER_STATUS_COLORS, ORDER_STATUS_ICONS,
  PAYMENT_METHOD_LABELS, ORDER_SOURCE_LABELS,
} from '@/utils/formatters';

function InfoRow({ label, value, mono }) {
  if (!value && value !== 0) return null;
  return (
    <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
      <span style={{ color: '#64748b', fontSize: 13, minWidth: 140, flexShrink: 0 }}>
        {label}
      </span>
      <span style={{
        fontSize: 13, fontWeight: 500, color: '#0f172a',
        fontFamily: mono ? 'monospace' : 'inherit',
      }}>
        {value}
      </span>
    </div>
  );
}

function Section({ title, children }) {
  return (
    <div style={{ marginBottom: 20 }}>
      <div style={{
        fontSize: 11, fontWeight: 700, textTransform: 'uppercase',
        letterSpacing: '0.06em', color: '#94a3b8', marginBottom: 12,
        paddingBottom: 6, borderBottom: '1px solid #f1f5f9',
      }}>
        {title}
      </div>
      {children}
    </div>
  );
}

export default function OrderDetailModal({ order, onClose, onChangeStatus }) {
  const { label: dlLabel, className: dlClass } =
    formatDeadline(order.deadline, order.hours_until_deadline);

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal modal-xl">
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <h2 className="modal-title">
              📋 {order.order_number}
            </h2>
            <span className={`badge ${ORDER_STATUS_COLORS[order.status]}`}>
              {ORDER_STATUS_ICONS[order.status]} {ORDER_STATUS_LABELS[order.status]}
            </span>
            <span className={`badge ${dlClass}`} style={{ fontSize: 11 }}>
              ⏰ {dlLabel}
            </span>
          </div>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>

        <div className="modal-body">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 32px' }}>

            {/* ── Chap ustun ──────────────────────────────────── */}
            <div>
              <Section title="👤 Mijoz">
                <InfoRow label="Ismi"     value={order.client?.full_name} />
                <InfoRow label="Telefon"  value={order.client?.phone} />
                <InfoRow label="Manba"    value={ORDER_SOURCE_LABELS[order.source]} />
              </Section>

              <Section title="📺 Televizor">
                <InfoRow label="Brand"      value={order.tv_brand} />
                <InfoRow label="Model"      value={order.tv_model} />
                <InfoRow label="Diagonali"  value={order.tv_diagonal} />
                <InfoRow label="Seriya #"   value={order.tv_serial_number} mono />
              </Section>

              <Section title="🔧 Nosozlik">
                <div style={{
                  fontSize: 13, color: '#374151', lineHeight: 1.6,
                  background: '#fafafa', padding: 12, borderRadius: 8,
                  border: '1px solid #f1f5f9',
                }}>
                  {order.problem_description || '—'}
                </div>
                {order.master_diagnosis && (
                  <div style={{ marginTop: 10 }}>
                    <div style={{ fontSize: 11.5, color: '#64748b', marginBottom: 4, fontWeight: 600 }}>
                      Usta tashxisi:
                    </div>
                    <div style={{
                      fontSize: 13, color: '#374151', lineHeight: 1.6,
                      background: '#f0fdf4', padding: 12, borderRadius: 8,
                      border: '1px solid #bbf7d0',
                    }}>
                      {order.master_diagnosis}
                    </div>
                  </div>
                )}
                {order.work_done && (
                  <div style={{ marginTop: 10 }}>
                    <div style={{ fontSize: 11.5, color: '#64748b', marginBottom: 4, fontWeight: 600 }}>
                      Bajarilgan ishlar:
                    </div>
                    <div style={{
                      fontSize: 13, color: '#374151', lineHeight: 1.6,
                      background: '#eff6ff', padding: 12, borderRadius: 8,
                      border: '1px solid #bfdbfe',
                    }}>
                      {order.work_done}
                    </div>
                  </div>
                )}
              </Section>
            </div>

            {/* ── O'ng ustun ──────────────────────────────────── */}
            <div>
              <Section title="👷 Ishchilar">
                <InfoRow label="Operator"  value={order.operator?.full_name} />
                <InfoRow label="Usta"      value={order.master?.full_name || 'Tayinlanmagan'} />
                <InfoRow label="Komisyon"  value={order.master_commission > 0
                  ? formatMoney(order.master_commission) : undefined} />
              </Section>

              <Section title="💰 Moliya">
                <InfoRow label="Taxminiy narx"  value={formatMoney(order.estimated_price)} />
                <InfoRow label="Zapchastlar"     value={formatMoney(order.parts_cost)} />
                <InfoRow label="Yakuniy narx"    value={formatMoney(order.final_price)} />
                <InfoRow label="To'lov holati"   value={
                  order.is_paid
                    ? `✅ To'langan (${PAYMENT_METHOD_LABELS[order.payment_method] || ''})`
                    : "⏳ To'lanmagan"
                } />
              </Section>

              <Section title="⏰ Vaqt belgilari">
                <InfoRow label="Qabul qilingan"  value={formatDate(order.created_at)} />
                <InfoRow label="Deadline"
                  value={
                    <span className={`badge ${dlClass}`} style={{ fontSize: 11 }}>
                      ⏰ {dlLabel}
                    </span>
                  }
                />
                <InfoRow label="Qabul vaqti"     value={formatDate(order.accepted_at)} />
                <InfoRow label="Tugallangan"      value={formatDate(order.completed_at)} />
                <InfoRow label="Topshirilgan"     value={formatDate(order.delivered_at)} />
                {order.cancel_reason && (
                  <InfoRow label="Bekor sababi"   value={order.cancel_reason} />
                )}
              </Section>

              {/* Status tarixi */}
              {order.status_history?.length > 0 && (
                <Section title="📜 Status tarixi">
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                    {[...order.status_history].reverse().map((h) => (
                      <div
                        key={h.id}
                        style={{
                          display: 'flex', gap: 8,
                          padding: '8px 12px',
                          background: '#fafafa', borderRadius: 8,
                          border: '1px solid #f1f5f9',
                          fontSize: 12,
                        }}
                      >
                        <div style={{ flex: 1 }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                            {h.old_status && (
                              <>
                                <span className={`badge ${ORDER_STATUS_COLORS[h.old_status]}`}
                                  style={{ fontSize: 10 }}>
                                  {ORDER_STATUS_LABELS[h.old_status]}
                                </span>
                                <span style={{ color: '#94a3b8' }}>→</span>
                              </>
                            )}
                            <span className={`badge ${ORDER_STATUS_COLORS[h.new_status]}`}
                              style={{ fontSize: 10 }}>
                              {ORDER_STATUS_LABELS[h.new_status]}
                            </span>
                          </div>
                          {h.comment && (
                            <div style={{ color: '#64748b', marginTop: 3 }}>{h.comment}</div>
                          )}
                        </div>
                        <div style={{ color: '#94a3b8', fontSize: 11, flexShrink: 0, textAlign: 'right' }}>
                          {h.changed_by?.full_name && (
                            <div style={{ fontWeight: 600, color: '#64748b' }}>
                              {h.changed_by.full_name}
                            </div>
                          )}
                          {formatDate(h.created_at)}
                        </div>
                      </div>
                    ))}
                  </div>
                </Section>
              )}
            </div>
          </div>
        </div>

        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose}>Yopish</button>
          {!['delivered','cancelled'].includes(order.status) && (
            <button
              className="btn btn-primary"
              onClick={() => { onClose(); onChangeStatus?.(order); }}
            >
              🔄 Holat o'zgartirish
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

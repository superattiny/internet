// ================================================
// Modal.jsx — Qayta ishlatiladigan modal wrapper
// ================================================

import { useEffect } from 'react';

export default function Modal({
  isOpen,
  onClose,
  title,
  size = 'md',       // sm | md | lg | xl
  children,
  footer,
  hideClose = false,
}) {
  // Body scroll'ni bloklash
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => { document.body.style.overflow = ''; };
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div
      className="modal-overlay"
      onClick={(e) => e.target === e.currentTarget && onClose?.()}
    >
      <div className={`modal modal-${size}`}>
        {/* Header */}
        {(title || !hideClose) && (
          <div className="modal-header">
            {title && <h2 className="modal-title">{title}</h2>}
            {!hideClose && (
              <button className="modal-close" onClick={onClose}>✕</button>
            )}
          </div>
        )}

        {/* Body */}
        <div className="modal-body">{children}</div>

        {/* Footer */}
        {footer && <div className="modal-footer">{footer}</div>}
      </div>
    </div>
  );
}

// ── Confirm dialog ───────────────────────────────────────────────
export function ConfirmModal({
  isOpen,
  onClose,
  onConfirm,
  title    = 'Tasdiqlash',
  message,
  confirmLabel = 'Tasdiqlash',
  cancelLabel  = 'Bekor qilish',
  variant  = 'danger',   // danger | warning | primary
  loading  = false,
}) {
  if (!isOpen) return null;

  const btnClass =
    variant === 'danger'  ? 'btn-danger'  :
    variant === 'warning' ? 'btn-secondary' :
    'btn-primary';

  const icon =
    variant === 'danger'  ? '⚠️' :
    variant === 'warning' ? '❕' :
    'ℹ️';

  return (
    <div
      className="modal-overlay"
      onClick={(e) => e.target === e.currentTarget && onClose?.()}
    >
      <div className="modal modal-sm">
        <div className="modal-body" style={{ paddingTop: 24, textAlign: 'center' }}>
          <div style={{ fontSize: 40, marginBottom: 12 }}>{icon}</div>
          <h3 style={{ fontSize: 17, fontWeight: 700, marginBottom: 8 }}>{title}</h3>
          {message && (
            <p style={{ fontSize: 14, color: '#64748b', lineHeight: 1.6 }}>{message}</p>
          )}
        </div>
        <div className="modal-footer" style={{ justifyContent: 'center', gap: 12 }}>
          <button className="btn btn-secondary" onClick={onClose} disabled={loading}>
            {cancelLabel}
          </button>
          <button className={`btn ${btnClass}`} onClick={onConfirm} disabled={loading}>
            {loading
              ? <><span className="spinner" style={{ width: 14, height: 14 }} /> Kutilmoqda...</>
              : confirmLabel
            }
          </button>
        </div>
      </div>
    </div>
  );
}

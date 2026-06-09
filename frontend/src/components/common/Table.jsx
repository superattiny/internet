// ================================================
// Table.jsx — Qayta ishlatiladigan jadval komponentlari
// ================================================

// ── Asosiy jadval wrapper ────────────────────────────────────────
export function Table({ children, className = '' }) {
  return (
    <div className={`table-wrapper ${className}`}>
      <table className="table">{children}</table>
    </div>
  );
}

// ── Bo'sh holat ──────────────────────────────────────────────────
export function EmptyState({ icon = '📭', title, text, action }) {
  return (
    <div className="empty-state">
      <div className="empty-icon">{icon}</div>
      {title && <div className="empty-title">{title}</div>}
      {text  && <div className="empty-text">{text}</div>}
      {action && <div style={{ marginTop: 16 }}>{action}</div>}
    </div>
  );
}

// ── Yuklanish skeleton ───────────────────────────────────────────
export function TableSkeleton({ rows = 5, cols = 6 }) {
  return (
    <table className="table">
      <tbody>
        {Array.from({ length: rows }).map((_, i) => (
          <tr key={i}>
            {Array.from({ length: cols }).map((_, j) => (
              <td key={j}>
                <div
                  style={{
                    height: 14,
                    borderRadius: 4,
                    background: 'linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%)',
                    backgroundSize: '200% 100%',
                    animation: 'shimmer 1.5s infinite',
                    width: j === 0 ? '80%' : j === cols - 1 ? '60%' : '90%',
                  }}
                />
              </td>
            ))}
          </tr>
        ))}
      </tbody>
      <style>{`
        @keyframes shimmer {
          0%   { background-position: 200% 0; }
          100% { background-position: -200% 0; }
        }
      `}</style>
    </table>
  );
}

// ── Pagination ───────────────────────────────────────────────────
export function Pagination({ currentPage, totalPages, total, pageSize, onPageChange }) {
  if (totalPages <= 1) return null;

  const from = (currentPage - 1) * pageSize + 1;
  const to   = Math.min(currentPage * pageSize, total);

  // Ko'rsatiladigan sahifalar (max 7)
  const getPages = () => {
    if (totalPages <= 7) return Array.from({ length: totalPages }, (_, i) => i + 1);
    const pages = [];
    const delta = 2;
    for (let i = 1; i <= totalPages; i++) {
      if (
        i === 1 || i === totalPages ||
        (i >= currentPage - delta && i <= currentPage + delta)
      ) {
        pages.push(i);
      } else if (pages[pages.length - 1] !== '...') {
        pages.push('...');
      }
    }
    return pages;
  };

  return (
    <div className="pagination">
      <span style={{ fontSize: 13, color: '#64748b' }}>
        {total} ta yozuvdan <b>{from}–{to}</b> ko'rsatilmoqda
      </span>
      <div className="pagination-btns">
        <button
          className="pg-btn"
          disabled={currentPage === 1}
          onClick={() => onPageChange(currentPage - 1)}
        >‹</button>

        {getPages().map((page, idx) =>
          page === '...' ? (
            <span
              key={`dots-${idx}`}
              style={{ padding: '0 4px', color: '#94a3b8', lineHeight: '32px' }}
            >…</span>
          ) : (
            <button
              key={page}
              className={`pg-btn${currentPage === page ? ' active' : ''}`}
              onClick={() => onPageChange(page)}
            >
              {page}
            </button>
          )
        )}

        <button
          className="pg-btn"
          disabled={currentPage === totalPages}
          onClick={() => onPageChange(currentPage + 1)}
        >›</button>
      </div>
    </div>
  );
}

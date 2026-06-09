// ================================================
// Orders.jsx — Zakazlar boshqaruv sahifasi
// Jadval, filter, yangi zakaz, status o'zgartirish
// ================================================

import { useEffect, useState, useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';
import useOrderStore from '@/store/orderStore';
import useAuthStore  from '@/store/authStore';
import ordersApi     from '@/api/ordersApi';
import NewOrderModal    from '@/components/Orders/NewOrderModal';
import StatusModal      from '@/components/Orders/StatusModal';
import OrderDetailModal from '@/components/Orders/OrderDetailModal';
import {
  formatDate, formatMoney, formatDeadline, formatTvInfo,
  ORDER_STATUS_LABELS, ORDER_STATUS_COLORS, ORDER_STATUS_ICONS,
  truncate,
} from '@/utils/formatters';
import { usePageTitle, useDebounce, useModal } from '@/utils/hooks';
import toast from 'react-hot-toast';

// Filtr status tugmalari
const STATUS_FILTERS = [
  { value: '',           label: 'Barchasi' },
  { value: 'new',        label: '🆕 Yangi' },
  { value: 'accepted',   label: '✅ Qabul' },
  { value: 'diagnosing', label: '🔍 Diagnostika' },
  { value: 'waiting',    label: '⏳ Kutmoqda' },
  { value: 'on_the_way', label: "🚗 Yo'lda" },
  { value: 'in_repair',  label: "🔧 Ta'mirda" },
  { value: 'done',       label: '✔️ Tayyor' },
  { value: 'delivered',  label: '🎉 Topshirildi' },
  { value: 'cancelled',  label: '❌ Bekor' },
];

export default function Orders() {
  usePageTitle('Zakazlar');
  const [searchParams] = useSearchParams();
  const { isAdminOrOperator } = useAuthStore();
  const {
    orders, total, totalPages, currentPage, overdueCount,
    isLoading, fetchOrders, setFilter, setPage, changeStatus,
  } = useOrderStore();

  // Modallar
  const newOrderModal  = useModal();
  const statusModal    = useModal();   // data = order
  const detailModal    = useModal();   // data = order

  // Filter holati
  const [searchInput,   setSearchInput]   = useState('');
  const [activeStatus,  setActiveStatus]  = useState(searchParams.get('status') || '');
  const [onlyOverdue,   setOnlyOverdue]   = useState(searchParams.get('only_overdue') === 'true');
  const [isArchived,    setIsArchived]    = useState(false);

  const debouncedSearch = useDebounce(searchInput, 400);

  // ── Zakazlarni yuklash ──────────────────────────────────────
  const load = useCallback(() => {
    fetchOrders({
      status:       activeStatus || undefined,
      search:       debouncedSearch || undefined,
      only_overdue: onlyOverdue,
      is_archived:  isArchived,
      page:         currentPage,
    });
  }, [activeStatus, debouncedSearch, onlyOverdue, isArchived, currentPage]);

  useEffect(() => { load(); }, [load]);

  // ── Filter tugmalari ────────────────────────────────────────
  const handleStatusFilter = (val) => {
    setActiveStatus(val);
    setFilter('status', val);
    setFilter('page', 1);
  };

  const handleSearch = (val) => {
    setSearchInput(val);
    setFilter('search', val);
    setFilter('page', 1);
  };

  const handleOverdueToggle = () => {
    const next = !onlyOverdue;
    setOnlyOverdue(next);
    setFilter('only_overdue', next);
    setFilter('page', 1);
  };

  // ── Zakaz yaratilganda ──────────────────────────────────────
  const handleCreated = (newOrder) => {
    load();
    toast.success(`📋 ${newOrder.order_number} yaratildi!`);
  };

  // ── Status yangilanganda ─────────────────────────────────────
  const handleStatusUpdated = (updatedOrder) => {
    load();
  };

  // ── Detail dan status modali ─────────────────────────────────
  const handleChangeStatusFromDetail = (order) => {
    statusModal.open(order);
  };

  // ── Arxivlash ────────────────────────────────────────────────
  const handleArchive = async (order, e) => {
    e.stopPropagation();
    if (!window.confirm(`"${order.order_number}" ni arxivlashni xohlaysizmi?`)) return;
    try {
      await ordersApi.archive(order.id);
      toast.success('📦 Arxivlandi');
      load();
    } catch (err) {
      toast.error(err.message || 'Xato');
    }
  };

  return (
    <div>
      {/* ── Overdue banner ──────────────────────────────────── */}
      {overdueCount > 0 && !onlyOverdue && (
        <div
          className="overdue-banner"
          style={{ marginBottom: 16, cursor: 'pointer' }}
          onClick={handleOverdueToggle}
        >
          <div className="overdue-banner-pulse" />
          <span style={{ fontWeight: 700 }}>
            ❌ {overdueCount} ta zakazning muddati o'tib ketdi!
          </span>
          <span style={{ fontSize: 13, marginLeft: 8, opacity: 0.8 }}>
            Filtrlash uchun bosing
          </span>
        </div>
      )}

      {/* ── Bosh toolbar ────────────────────────────────────── */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        flexWrap: 'wrap', gap: 12, marginBottom: 16,
      }}>
        {/* Qidiruv */}
        <div className="search-bar" style={{ maxWidth: 280 }}>
          <span className="search-icon">🔍</span>
          <input
            placeholder="Zakaz # yoki mijoz..."
            value={searchInput}
            onChange={(e) => handleSearch(e.target.value)}
          />
        </div>

        {/* O'ng tugmalar */}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          {/* Arxiv toggle */}
          <button
            className={`btn ${isArchived ? 'btn-secondary' : 'btn-ghost'}`}
            onClick={() => { setIsArchived((p) => !p); setFilter('is_archived', !isArchived); }}
          >
            📦 {isArchived ? 'Arxiv (faol)' : 'Arxiv'}
          </button>

          {/* Overdue toggle */}
          <button
            className={`btn ${onlyOverdue ? 'btn-danger' : 'btn-ghost'}`}
            onClick={handleOverdueToggle}
          >
            {onlyOverdue ? '❌ Muddati o\'tgan' : '⚠️ Muddati o\'tgan'}
          </button>

          {/* Yangi zakaz */}
          {isAdminOrOperator() && (
            <button className="btn btn-primary" onClick={() => newOrderModal.open()}>
              ＋ Yangi zakaz
            </button>
          )}
        </div>
      </div>

      {/* ── Status filtrlari ────────────────────────────────── */}
      <div className="filter-bar" style={{ marginBottom: 16, overflowX: 'auto', flexWrap: 'nowrap' }}>
        {STATUS_FILTERS.map((f) => (
          <button
            key={f.value}
            className={`filter-btn${activeStatus === f.value ? ' active' : ''}`}
            onClick={() => handleStatusFilter(f.value)}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* ── Jadval kartasi ──────────────────────────────────── */}
      <div className="card">
        {/* Jadval sarlavhasi */}
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '16px 20px 12px',
        }}>
          <span style={{ fontSize: 13, color: '#64748b' }}>
            Jami:{' '}
            <b style={{ color: '#0f172a' }}>{total}</b> ta zakaz
            {onlyOverdue && (
              <span className="badge deadline-overdue" style={{ marginLeft: 8, fontSize: 11 }}>
                Muddati o'tganlar
              </span>
            )}
          </span>
          <button
            className="btn btn-ghost btn-sm"
            onClick={load}
            disabled={isLoading}
            title="Yangilash"
          >
            {isLoading ? <span className="spinner" style={{ width: 14, height: 14 }} /> : '🔄'}
          </button>
        </div>

        {/* ── Jadval ──────────────────────────────────────── */}
        <div className="table-wrapper" style={{ border: 'none', borderRadius: 0 }}>
          {isLoading && orders.length === 0 ? (
            <div className="page-loader" style={{ minHeight: 200 }}>
              <div className="spinner" />
              <span>Yuklanmoqda...</span>
            </div>
          ) : orders.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">📋</div>
              <div className="empty-title">Zakazlar topilmadi</div>
              <div className="empty-text">
                {onlyOverdue
                  ? 'Muddati o\'tgan zakazlar yo\'q — yaxshi!'
                  : 'Filter o\'zgartiring yoki yangi zakaz qo\'shing'}
              </div>
            </div>
          ) : (
            <table className="table">
              <thead>
                <tr>
                  <th>Raqam</th>
                  <th>Mijoz</th>
                  <th>Televizor</th>
                  <th>Nosozlik</th>
                  <th>Holat</th>
                  <th>Deadline</th>
                  <th>Usta</th>
                  <th>Narx</th>
                  <th>Amallar</th>
                </tr>
              </thead>
              <tbody>
                {orders.map((order) => {
                  const { label: dlLabel, className: dlClass, isOverdue } =
                    formatDeadline(order.deadline, order.hours_until_deadline);

                  return (
                    <tr
                      key={order.id}
                      style={{
                        cursor: 'pointer',
                        background: isOverdue ? '#fff8f8' : undefined,
                      }}
                      onClick={() => detailModal.open(order)}
                    >
                      {/* Raqam */}
                      <td>
                        <span style={{
                          fontFamily: 'monospace', fontWeight: 700,
                          color: '#2563eb', fontSize: 13,
                        }}>
                          {order.order_number}
                        </span>
                        <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>
                          {formatDate(order.created_at).split(',')[0]}
                        </div>
                      </td>

                      {/* Mijoz */}
                      <td>
                        <div style={{ fontWeight: 600, fontSize: 13 }}>
                          {order.client?.full_name || '—'}
                        </div>
                        <div style={{ fontSize: 11, color: '#94a3b8' }}>
                          {order.client?.phone || ''}
                        </div>
                      </td>

                      {/* Televizor */}
                      <td style={{ fontSize: 12 }}>
                        <div style={{ fontWeight: 500 }}>
                          {order.tv_brand || '—'}{order.tv_model ? ` ${order.tv_model}` : ''}
                        </div>
                        {order.tv_diagonal && (
                          <div style={{ color: '#94a3b8' }}>{order.tv_diagonal}</div>
                        )}
                      </td>

                      {/* Nosozlik */}
                      <td style={{ maxWidth: 160 }}>
                        <div
                          style={{
                            fontSize: 12, color: '#374151',
                            overflow: 'hidden', whiteSpace: 'nowrap',
                            textOverflow: 'ellipsis', maxWidth: 150,
                          }}
                          title={order.problem_description}
                        >
                          {truncate(order.problem_description, 40)}
                        </div>
                      </td>

                      {/* Holat */}
                      <td>
                        <span className={`badge ${ORDER_STATUS_COLORS[order.status]}`}>
                          {ORDER_STATUS_ICONS[order.status]}{' '}
                          {ORDER_STATUS_LABELS[order.status]}
                        </span>
                      </td>

                      {/* Deadline */}
                      <td>
                        <span
                          className={`badge ${dlClass}`}
                          style={{ fontSize: 11 }}
                        >
                          {dlLabel}
                        </span>
                      </td>

                      {/* Usta */}
                      <td style={{ fontSize: 12 }}>
                        {order.master?.full_name || (
                          <span style={{ color: '#cbd5e1' }}>—</span>
                        )}
                      </td>

                      {/* Narx */}
                      <td style={{ fontSize: 12 }}>
                        {order.is_paid ? (
                          <span style={{ color: '#16a34a', fontWeight: 700 }}>
                            {formatMoney(order.final_price)}
                          </span>
                        ) : order.estimated_price > 0 ? (
                          <span style={{ color: '#64748b' }}>
                            ~{formatMoney(order.estimated_price)}
                          </span>
                        ) : (
                          <span style={{ color: '#cbd5e1' }}>—</span>
                        )}
                      </td>

                      {/* Amallar */}
                      <td onClick={(e) => e.stopPropagation()}>
                        <div className="table-actions">
                          {/* Status o'zgartirish */}
                          {!['delivered', 'cancelled'].includes(order.status) && (
                            <button
                              className="btn btn-ghost btn-sm"
                              onClick={() => statusModal.open(order)}
                              title="Holat o'zgartirish"
                            >
                              🔄
                            </button>
                          )}
                          {/* Arxivlash */}
                          {['delivered', 'cancelled'].includes(order.status) &&
                           !order.is_archived && (
                            <button
                              className="btn btn-ghost btn-sm"
                              onClick={(e) => handleArchive(order, e)}
                              title="Arxivlash"
                            >
                              📦
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>

        {/* ── Pagination ──────────────────────────────────── */}
        {totalPages > 1 && (
          <div className="pagination">
            <span>
              {total} ta zakazdan{' '}
              {(currentPage - 1) * 20 + 1}–{Math.min(currentPage * 20, total)} ko'rsatilmoqda
            </span>
            <div className="pagination-btns">
              <button
                className="pg-btn"
                disabled={currentPage === 1}
                onClick={() => setPage(currentPage - 1)}
              >
                ‹
              </button>
              {Array.from({ length: Math.min(totalPages, 7) }, (_, i) => {
                const page = i + 1;
                return (
                  <button
                    key={page}
                    className={`pg-btn${currentPage === page ? ' active' : ''}`}
                    onClick={() => setPage(page)}
                  >
                    {page}
                  </button>
                );
              })}
              <button
                className="pg-btn"
                disabled={currentPage === totalPages}
                onClick={() => setPage(currentPage + 1)}
              >
                ›
              </button>
            </div>
          </div>
        )}
      </div>

      {/* ── Modallar ──────────────────────────────────────── */}
      {newOrderModal.isOpen && (
        <NewOrderModal
          onClose={newOrderModal.close}
          onCreated={handleCreated}
        />
      )}

      {statusModal.isOpen && statusModal.data && (
        <StatusModal
          order={statusModal.data}
          onClose={statusModal.close}
          onUpdated={handleStatusUpdated}
        />
      )}

      {detailModal.isOpen && detailModal.data && (
        <OrderDetailModal
          order={detailModal.data}
          onClose={detailModal.close}
          onChangeStatus={handleChangeStatusFromDetail}
        />
      )}
    </div>
  );
}

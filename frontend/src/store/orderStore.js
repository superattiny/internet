// ================================================
// orderStore.js — Zakazlar global holati
// ================================================

import { create } from 'zustand';
import ordersApi from '@/api/ordersApi';

const useOrderStore = create((set, get) => ({
  // ── Holat ────────────────────────────────────────────────────
  orders:         [],
  total:          0,
  totalPages:     1,
  currentPage:    1,
  overdueCount:   0,
  stats:          null,
  deadlineAlerts: [],
  isLoading:      false,
  error:          null,

  // Aktiv filterlar
  filters: {
    status:       '',
    search:       '',
    only_overdue: false,
    is_archived:  false,
    page:         1,
    page_size:    20,
  },

  // ── Ro'yxatni yuklash ────────────────────────────────────────
  fetchOrders: async (extraFilters = {}) => {
    set({ isLoading: true, error: null });
    try {
      const filters = { ...get().filters, ...extraFilters };
      // Bo'sh qiymatlarni olib tashlash
      const params = Object.fromEntries(
        Object.entries(filters).filter(([, v]) => v !== '' && v !== false && v != null)
      );
      const data = await ordersApi.getList(params);
      set({
        orders:       data.items,
        total:        data.total,
        totalPages:   data.total_pages,
        currentPage:  data.page,
        overdueCount: data.overdue_count,
        isLoading:    false,
        filters,
      });
    } catch (err) {
      set({ isLoading: false, error: err.message });
    }
  },

  // ── Filterlarni o'zgartirish ─────────────────────────────────
  setFilter: (key, value) => {
    set((s) => ({
      filters: { ...s.filters, [key]: value, page: 1 },
    }));
  },

  setPage: (page) => {
    set((s) => ({ filters: { ...s.filters, page } }));
  },

  // ── Statistika ────────────────────────────────────────────────
  fetchStats: async () => {
    try {
      const stats = await ordersApi.getStats();
      set({ stats });
    } catch (_) {}
  },

  // ── Deadline alertlar ─────────────────────────────────────────
  fetchDeadlineAlerts: async () => {
    try {
      const alerts = await ordersApi.getDeadlineAlerts(24);
      set({ deadlineAlerts: alerts });
    } catch (_) {}
  },

  // ── Zakaz statusini o'zgartirish ──────────────────────────────
  changeStatus: async (id, newStatus, comment) => {
    try {
      const updated = await ordersApi.changeStatus(id, newStatus, comment);
      // Ro'yxatdagi zakazni yangilash
      set((s) => ({
        orders: s.orders.map((o) => (o.id === id ? updated : o)),
      }));
      return { success: true, data: updated };
    } catch (err) {
      return { success: false, error: err.message };
    }
  },

  // ── Xatoni tozalash ───────────────────────────────────────────
  clearError: () => set({ error: null }),
}));

export default useOrderStore;

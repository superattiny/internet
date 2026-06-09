// ================================================
// ordersApi.js — Zakazlar API funksiyalari
// ================================================

import api from './axiosInstance';

const ordersApi = {
  // ── Ro'yxat (filter + pagination) ──────────────────────────
  getList: async (params = {}) => {
    // params: { page, page_size, status, master_id, search, is_archived, only_overdue }
    const { data } = await api.get('/orders/', { params });
    return data;   // OrderListResponse
  },

  // ── Bitta zakaz ─────────────────────────────────────────────
  getById: async (id) => {
    const { data } = await api.get(`/orders/${id}`);
    return data;
  },

  // Raqam bo'yicha (TV-2025-0001)
  getByNumber: async (orderNumber) => {
    const { data } = await api.get(`/orders/by-number/${orderNumber}`);
    return data;
  },

  // ── Yaratish ────────────────────────────────────────────────
  create: async (orderData) => {
    const { data } = await api.post('/orders/', orderData);
    return data;
  },

  // ── Yangilash (PATCH) ───────────────────────────────────────
  update: async (id, updateData) => {
    const { data } = await api.patch(`/orders/${id}`, updateData);
    return data;
  },

  // ── Status o'zgartirish ─────────────────────────────────────
  changeStatus: async (id, newStatus, comment = '') => {
    const { data } = await api.post(`/orders/${id}/status`, {
      new_status: newStatus,
      comment:    comment || undefined,
    });
    return data;
  },

  // ── To'lov qabul qilish ─────────────────────────────────────
  acceptPayment: async (id, finalPrice, paymentMethod, comment = '') => {
    const { data } = await api.post(`/orders/${id}/payment`, {
      final_price:    finalPrice,
      payment_method: paymentMethod,
      comment:        comment || undefined,
    });
    return data;
  },

  // ── Arxivlash ───────────────────────────────────────────────
  archive: async (id) => {
    const { data } = await api.post(`/orders/${id}/archive`);
    return data;
  },

  // ── Statistika (Dashboard) ──────────────────────────────────
  getStats: async () => {
    const { data } = await api.get('/orders/stats');
    return data;
  },

  // ── Deadline ogohlantirishlari ──────────────────────────────
  getDeadlineAlerts: async (warningHours = 24) => {
    const { data } = await api.get('/orders/alerts/deadline', {
      params: { warning_hours: warningHours },
    });
    return data;   // OrderDeadlineAlertResponse[]
  },
};

export default ordersApi;

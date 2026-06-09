// ================================================
// workersApi.js — Ishchilar API funksiyalari
// ================================================

import api from './axiosInstance';

const workersApi = {
  // ── Ro'yxat ─────────────────────────────────────────────────
  getList: async (params = {}) => {
    // params: { role, is_active, page, page_size }
    const { data } = await api.get('/workers/', { params });
    return data;   // WorkerListResponse
  },

  // ── Bitta ishchi ────────────────────────────────────────────
  getById: async (id) => {
    const { data } = await api.get(`/workers/${id}`);
    return data;
  },

  // ── Yaratish [Admin] ────────────────────────────────────────
  create: async (workerData) => {
    const { data } = await api.post('/workers/', workerData);
    return data;
  },

  // ── Yangilash [Admin] ───────────────────────────────────────
  update: async (id, updateData) => {
    const { data } = await api.patch(`/workers/${id}`, updateData);
    return data;
  },

  // ── Bloklash / Faollashtirish [Admin] ───────────────────────
  deactivate: async (id) => {
    const { data } = await api.delete(`/workers/${id}`);
    return data;
  },

  activate: async (id) => {
    const { data } = await api.post(`/workers/${id}/activate`);
    return data;
  },

  // ── Balans tarixi ───────────────────────────────────────────
  getBalanceHistory: async (id) => {
    const { data } = await api.get(`/workers/${id}/balance`);
    return data;
  },

  // ── O'z balansi (Usta uchun) ─────────────────────────────────
  getMyBalance: async () => {
    const { data } = await api.get('/workers/me/balance');
    return data;
  },

  // ── Ish haqi to'lash [Admin] ────────────────────────────────
  paySalary: async (id, amount, paymentMethod, notes = '') => {
    const { data } = await api.post(`/workers/${id}/salary`, {
      amount,
      payment_method: paymentMethod,
      notes: notes || undefined,
    });
    return data;
  },

  // ── Balans tuzatish [Admin] ─────────────────────────────────
  adjustBalance: async (id, amount, reason) => {
    const { data } = await api.post(`/workers/${id}/balance/adjust`, {
      amount,
      reason,
    });
    return data;
  },

  // ── Moliyaviy xulosa [Admin] ────────────────────────────────
  getFinanceSummary: async () => {
    const { data } = await api.get('/workers/summary');
    return data;
  },
};

export default workersApi;

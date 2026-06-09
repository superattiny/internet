// ================================================
// axiosInstance.js — Markaziy Axios sozlamalari
// Barcha API so'rovlari shu instance orqali o'tadi
// ================================================

import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || '/api/v1';

const api = axios.create({
  baseURL: BASE_URL,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
});

// ── Request interceptor: tokenni qo'shadi ──────────────────
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error),
);

// ── Response interceptor: xatolarni markaziy ushlaydi ──────
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;

    // 401 — Token muddati o'tgan yoki noto'g'ri
    if (status === 401) {
      localStorage.removeItem('access_token');
      localStorage.removeItem('user');
      // Login sahifasiga yo'naltirish
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }

    // Xato xabarini standartlashtirish
    const message =
      error.response?.data?.detail ||
      error.response?.data?.message ||
      error.message ||
      'Noma\'lum xato yuz berdi';

    return Promise.reject({ ...error, message });
  },
);

export default api;

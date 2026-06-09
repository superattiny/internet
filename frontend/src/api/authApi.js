// ================================================
// authApi.js — Autentifikatsiya API funksiyalari
// POST /auth/login, GET /auth/me, POST /auth/logout
// ================================================

import api from './axiosInstance';

const authApi = {
  // Tizimga kirish
  login: async (username, password) => {
    const { data } = await api.post('/auth/login', { username, password });
    return data;   // { access_token, token_type, expires_in, user }
  },

  // Tizimdan chiqish
  logout: async () => {
    try {
      await api.post('/auth/logout');
    } finally {
      localStorage.removeItem('access_token');
      localStorage.removeItem('user');
    }
  },

  // Joriy foydalanuvchi ma'lumoti
  getMe: async () => {
    const { data } = await api.get('/auth/me');
    return data;
  },

  // Tokenni yangilash
  refreshToken: async () => {
    const { data } = await api.post('/auth/refresh');
    return data;
  },

  // Parolni o'zgartirish
  changePassword: async (currentPassword, newPassword, confirmPassword) => {
    const { data } = await api.post('/auth/change-password', {
      current_password: currentPassword,
      new_password:     newPassword,
      confirm_password: confirmPassword,
    });
    return data;
  },
};

export default authApi;

// ================================================
// authStore.js — Zustand autentifikatsiya store
// Login, logout, token va user holati saqlanadi
// ================================================

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import authApi from '@/api/authApi';

const useAuthStore = create(
  persist(
    (set, get) => ({
      // ── Holat ────────────────────────────────────────────────
      user:        null,    // { id, username, full_name, role, balance, ... }
      token:       null,    // JWT string
      isLoading:   false,
      error:       null,
      isLoggedIn:  false,

      // ── Login ────────────────────────────────────────────────
      login: async (username, password) => {
        set({ isLoading: true, error: null });
        try {
          const data = await authApi.login(username, password);

          // Token va user'ni localStorage + state ga saqlash
          localStorage.setItem('access_token', data.access_token);
          localStorage.setItem('user', JSON.stringify(data.user));

          set({
            user:       data.user,
            token:      data.access_token,
            isLoggedIn: true,
            isLoading:  false,
            error:      null,
          });

          return { success: true, user: data.user };
        } catch (err) {
          const message = err.message || 'Login amalga oshmadi';
          set({ isLoading: false, error: message, isLoggedIn: false });
          return { success: false, error: message };
        }
      },

      // ── Logout ───────────────────────────────────────────────
      logout: async () => {
        try { await authApi.logout(); } catch (_) {}
        localStorage.removeItem('access_token');
        localStorage.removeItem('user');
        set({ user: null, token: null, isLoggedIn: false, error: null });
      },

      // ── Profilni yangilash ───────────────────────────────────
      refreshUser: async () => {
        try {
          const user = await authApi.getMe();
          set({ user });
          localStorage.setItem('user', JSON.stringify(user));
        } catch (_) {}
      },

      // ── Xatoni tozalash ──────────────────────────────────────
      clearError: () => set({ error: null }),

      // ── Ruxsatlarni tekshirish ───────────────────────────────
      isAdmin:    () => get().user?.role === 'admin',
      isOperator: () => get().user?.role === 'operator',
      isMaster:   () => get().user?.role === 'master',
      isAdminOrOperator: () =>
        ['admin', 'operator'].includes(get().user?.role),
    }),
    {
      name:    'tv-crm-auth',          // localStorage key
      partialize: (state) => ({        // Faqat shu maydonlar saqlanadi
        user:       state.user,
        token:      state.token,
        isLoggedIn: state.isLoggedIn,
      }),
    },
  ),
);

export default useAuthStore;

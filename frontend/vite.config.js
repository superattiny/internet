// vite.config.js — Vite sozlamalari
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],

  resolve: {
    alias: {
      // @ = src/ — import '@/api/axiosInstance' yozish uchun
      '@': path.resolve(__dirname, './src'),
    },
  },

  server: {
    port: 5173,
    // Backend API ga proxy — CORS muammosini hal qiladi
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        secure: false,
      },
    },
  },
});

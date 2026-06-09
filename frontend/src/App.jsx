// ================================================
// App.jsx — Markaziy routing va sahifalar
// ================================================

import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';

import MainLayout from '@/components/Layout/MainLayout';
import Login      from '@/pages/Login';
import Dashboard  from '@/pages/Dashboard';
import Orders     from '@/pages/Orders';

// ── Placeholder sahifalar (keyingi bosqichlar uchun) ─────────────
function ComingSoon({ title, icon }) {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      justifyContent: 'center', minHeight: 400, gap: 16,
      color: '#94a3b8',
    }}>
      <div style={{ fontSize: 64 }}>{icon}</div>
      <h2 style={{ fontSize: 22, fontWeight: 700, color: '#64748b' }}>
        {title}
      </h2>
      <p style={{ fontSize: 14 }}>
        Bu sahifa keyingi bosqichda quriladi
      </p>
      <div style={{
        display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'center',
      }}>
        {['Backend API', 'Jadval', 'Modallar', 'Filtrlar'].map((item) => (
          <span
            key={item}
            style={{
              padding: '4px 12px', borderRadius: 20,
              background: '#f1f5f9', color: '#64748b',
              fontSize: 12, fontWeight: 500,
            }}
          >
            {item}
          </span>
        ))}
      </div>
    </div>
  );
}

// ── Auth Guard — himoyalangan sahifalar ──────────────────────────
function ProtectedRoute({ children }) {
  return <MainLayout>{children}</MainLayout>;
}

export default function App() {
  return (
    <BrowserRouter>
      {/* Toast bildirishnomalar */}
      <Toaster
        position="top-right"
        toastOptions={{
          duration: 4000,
          style: {
            fontFamily: 'Inter, sans-serif',
            fontSize:   '13.5px',
            fontWeight: '500',
            borderRadius: '10px',
            boxShadow: '0 8px 24px rgba(0,0,0,0.12)',
            padding: '12px 16px',
          },
          success: {
            style: {
              background: '#f0fdf4',
              color:      '#15803d',
              border:     '1px solid #bbf7d0',
            },
            iconTheme: { primary: '#16a34a', secondary: '#dcfce7' },
          },
          error: {
            duration: 6000,
            style: {
              background: '#fef2f2',
              color:      '#dc2626',
              border:     '1px solid #fca5a5',
            },
            iconTheme: { primary: '#dc2626', secondary: '#fee2e2' },
          },
        }}
      />

      <Routes>
        {/* ── Public ─────────────────────────────────────────── */}
        <Route path="/login" element={<Login />} />

        {/* ── Asosiy sahifalar ────────────────────────────────── */}
        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <Dashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/orders"
          element={
            <ProtectedRoute>
              <Orders />
            </ProtectedRoute>
          }
        />

        {/* ── Keyingi bosqichlarda to'liq quriladi ─────────────── */}
        <Route
          path="/workers"
          element={
            <ProtectedRoute>
              <ComingSoon title="Ishchilar" icon="👷" />
            </ProtectedRoute>
          }
        />
        <Route
          path="/clients"
          element={
            <ProtectedRoute>
              <ComingSoon title="Mijozlar" icon="👥" />
            </ProtectedRoute>
          }
        />
        <Route
          path="/warehouse"
          element={
            <ProtectedRoute>
              <ComingSoon title="Ombor" icon="🏪" />
            </ProtectedRoute>
          }
        />
        <Route
          path="/finance"
          element={
            <ProtectedRoute>
              <ComingSoon title="Moliya" icon="💰" />
            </ProtectedRoute>
          }
        />
        <Route
          path="/archive"
          element={
            <ProtectedRoute>
              <ComingSoon title="Arxiv" icon="📦" />
            </ProtectedRoute>
          }
        />

        {/* ── Redirect'lar ────────────────────────────────────── */}
        <Route path="/"     element={<Navigate to="/dashboard" replace />} />
        <Route path="*"     element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  );
}

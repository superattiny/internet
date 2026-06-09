// ================================================
// Login.jsx — Tizimga kirish sahifasi
// ================================================

import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import useAuthStore from '@/store/authStore';
import { usePageTitle } from '@/utils/hooks';

export default function Login() {
  usePageTitle('Kirish');
  const navigate = useNavigate();
  const { login, isLoading, error, isLoggedIn, clearError } = useAuthStore();

  const [form, setForm]           = useState({ username: '', password: '' });
  const [showPass, setShowPass]   = useState(false);
  const [fieldErr, setFieldErr]   = useState({});

  // Allaqachon kirgan bo'lsa — dashboard ga
  useEffect(() => {
    if (isLoggedIn) navigate('/dashboard', { replace: true });
  }, [isLoggedIn, navigate]);

  // Xatolarni tozalash
  useEffect(() => {
    if (error) {
      const t = setTimeout(clearError, 5000);
      return () => clearTimeout(t);
    }
  }, [error, clearError]);

  // ── Forma o'zgarishi ──────────────────────────────────────────
  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((p) => ({ ...p, [name]: value }));
    if (fieldErr[name]) setFieldErr((p) => ({ ...p, [name]: '' }));
  };

  // ── Validatsiya ───────────────────────────────────────────────
  const validate = () => {
    const errs = {};
    if (!form.username.trim()) errs.username = 'Login kiritilishi shart';
    else if (form.username.length < 3)
      errs.username = "Login kamida 3 ta belgi bo'lishi kerak";
    if (!form.password)         errs.password = 'Parol kiritilishi shart';
    else if (form.password.length < 4)
      errs.password = "Parol kamida 4 ta belgi bo'lishi kerak";
    setFieldErr(errs);
    return Object.keys(errs).length === 0;
  };

  // ── Submit ────────────────────────────────────────────────────
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;

    const result = await login(form.username.trim().toLowerCase(), form.password);
    if (result.success) navigate('/dashboard', { replace: true });
  };

  // ── Enter tugmasi ─────────────────────────────────────────────
  const handleKeyDown = (e) => {
    if (e.key === 'Enter') handleSubmit(e);
  };

  return (
    <div className="login-page">
      {/* Fon animatsiya doiralari */}
      <div className="login-bg-circle" />
      <div className="login-bg-circle" />
      <div className="login-bg-circle" />

      <div className="login-card">
        {/* Logo va sarlavha */}
        <div className="login-header">
          <div className="login-logo">📺</div>
          <h1 className="login-title">TV CRM</h1>
          <p className="login-subtitle">
            Ustaxona boshqaruv tizimiga xush kelibsiz
          </p>
        </div>

        {/* Xato xabari */}
        {error && (
          <div className="alert alert-danger" style={{ marginBottom: 16 }}>
            <span className="alert-icon">⚠️</span>
            <div className="alert-text">{error}</div>
          </div>
        )}

        {/* Forma */}
        <form onSubmit={handleSubmit} noValidate>
          {/* Username */}
          <div className="form-group">
            <label className="form-label">
              Foydalanuvchi nomi
              <span className="required"> *</span>
            </label>
            <div className="input-group">
              <span className="input-icon">👤</span>
              <input
                className={`form-input${fieldErr.username ? ' error' : ''}`}
                type="text"
                name="username"
                value={form.username}
                onChange={handleChange}
                onKeyDown={handleKeyDown}
                placeholder="admin"
                autoComplete="username"
                autoFocus
                disabled={isLoading}
              />
            </div>
            {fieldErr.username && (
              <div className="form-error">{fieldErr.username}</div>
            )}
          </div>

          {/* Parol */}
          <div className="form-group">
            <label className="form-label">
              Parol
              <span className="required"> *</span>
            </label>
            <div className="input-group">
              <span className="input-icon">🔒</span>
              <input
                className={`form-input${fieldErr.password ? ' error' : ''}`}
                type={showPass ? 'text' : 'password'}
                name="password"
                value={form.password}
                onChange={handleChange}
                onKeyDown={handleKeyDown}
                placeholder="••••••••"
                autoComplete="current-password"
                disabled={isLoading}
                style={{ paddingRight: 40 }}
              />
              <button
                type="button"
                className="input-icon-right"
                onClick={() => setShowPass((p) => !p)}
                tabIndex={-1}
                style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 16 }}
                title={showPass ? "Parolni yashirish" : "Parolni ko'rsatish"}
              >
                {showPass ? '🙈' : '👁️'}
              </button>
            </div>
            {fieldErr.password && (
              <div className="form-error">{fieldErr.password}</div>
            )}
          </div>

          {/* Kirish tugmasi */}
          <button
            type="submit"
            className="btn btn-primary btn-lg"
            style={{ width: '100%', marginTop: 8, justifyContent: 'center' }}
            disabled={isLoading}
          >
            {isLoading ? (
              <>
                <span className="spinner" style={{ width: 16, height: 16 }} />
                Kirilmoqda...
              </>
            ) : (
              <>
                🔐 Tizimga kirish
              </>
            )}
          </button>
        </form>

        {/* Footer */}
        <div
          style={{
            marginTop: 24,
            paddingTop: 16,
            borderTop: '1px solid #f1f5f9',
            textAlign: 'center',
          }}
        >
          <p style={{ fontSize: 12, color: '#94a3b8', lineHeight: 1.6 }}>
            📺 TV Ta'mirlash Ustaxonasi
            <br />
            <span style={{ color: '#cbd5e1' }}>
              CRM Boshqaruv Tizimi v1.0
            </span>
          </p>
        </div>

        {/* Demo hisob ma'lumoti (faqat development) */}
        {import.meta.env.DEV && (
          <div
            style={{
              marginTop: 12,
              padding: '10px 14px',
              background: '#f0f9ff',
              border: '1px solid #bae6fd',
              borderRadius: 8,
            }}
          >
            <p style={{ fontSize: 11.5, color: '#0369a1', marginBottom: 6, fontWeight: 600 }}>
              🧪 Test hisob:
            </p>
            <div style={{ display: 'flex', gap: 8 }}>
              <button
                type="button"
                style={{
                  flex: 1, padding: '6px 10px',
                  background: '#e0f2fe', border: '1px solid #7dd3fc',
                  borderRadius: 6, fontSize: 12, cursor: 'pointer', color: '#0369a1',
                }}
                onClick={() => setForm({ username: 'admin', password: 'admin123' })}
              >
                👑 Admin
              </button>
              <button
                type="button"
                style={{
                  flex: 1, padding: '6px 10px',
                  background: '#e0f2fe', border: '1px solid #7dd3fc',
                  borderRadius: 6, fontSize: 12, cursor: 'pointer', color: '#0369a1',
                }}
                onClick={() => setForm({ username: 'operator1', password: 'pass123' })}
              >
                🖥️ Operator
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

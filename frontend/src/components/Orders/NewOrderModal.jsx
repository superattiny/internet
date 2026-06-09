// ================================================
// NewOrderModal.jsx — Yangi zakaz qo'shish modali
// ================================================

import { useState, useEffect } from 'react';
import ordersApi  from '@/api/ordersApi';
import workersApi from '@/api/workersApi';
import { ORDER_SOURCE_LABELS } from '@/utils/formatters';
import toast from 'react-hot-toast';

const SOURCES = Object.entries(ORDER_SOURCE_LABELS);
const TV_BRANDS = ['Samsung', 'LG', 'Sony', 'Philips', 'TCL', 'Hisense', 'Artel', 'Boshqa'];

// Bugundan N kun keyingi datetime-local qiymat
const defaultDeadline = (daysAhead = 3) => {
  const d = new Date();
  d.setDate(d.getDate() + daysAhead);
  d.setHours(18, 0, 0, 0);
  return d.toISOString().slice(0, 16);
};

export default function NewOrderModal({ onClose, onCreated }) {
  const [masters,  setMasters]  = useState([]);
  const [saving,   setSaving]   = useState(false);
  const [errors,   setErrors]   = useState({});

  const [form, setForm] = useState({
    // Mijoz
    client_name:  '',
    client_phone: '',
    // TV
    tv_brand:         '',
    tv_model:         '',
    tv_diagonal:      '',
    tv_serial_number: '',
    // Zakaz
    problem_description: '',
    source:              'walk_in',
    estimated_price:     '',
    master_id:           '',
    // Deadline — MAJBURIY
    deadline: defaultDeadline(3),
  });

  // Ustalar ro'yxatini yuklash
  useEffect(() => {
    workersApi.getList({ role: 'master', is_active: true, page_size: 50 })
      .then((d) => setMasters(d.items || []))
      .catch(() => {});
  }, []);

  const set = (field, value) => {
    setForm((p) => ({ ...p, [field]: value }));
    if (errors[field]) setErrors((p) => ({ ...p, [field]: '' }));
  };

  // ── Validatsiya ─────────────────────────────────────────────
  const validate = () => {
    const e = {};
    if (!form.client_name.trim())          e.client_name  = 'Mijoz ismi kiritilishi shart';
    if (!form.problem_description.trim() || form.problem_description.length < 5)
      e.problem_description = "Nosozlik tavsifi kamida 5 ta belgi bo'lishi kerak";
    if (!form.deadline)                    e.deadline     = 'Deadline kiritilishi shart';
    else {
      const dl = new Date(form.deadline);
      if (dl <= new Date())                e.deadline     = "Deadline o'tgan vaqt bo'lishi mumkin emas";
    }
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  // ── Saqlash ──────────────────────────────────────────────────
  const handleSave = async () => {
    if (!validate()) return;
    setSaving(true);
    try {
      const payload = {
        client_name:         form.client_name.trim(),
        client_phone:        form.client_phone.trim() || undefined,
        tv_brand:            form.tv_brand || undefined,
        tv_model:            form.tv_model.trim() || undefined,
        tv_diagonal:         form.tv_diagonal.trim() || undefined,
        tv_serial_number:    form.tv_serial_number.trim() || undefined,
        problem_description: form.problem_description.trim(),
        source:              form.source,
        estimated_price:     parseFloat(form.estimated_price) || 0,
        master_id:           form.master_id ? parseInt(form.master_id) : undefined,
        deadline:            new Date(form.deadline).toISOString(),
      };
      const created = await ordersApi.create(payload);
      toast.success(`✅ Zakaz yaratildi: ${created.order_number}`);
      onCreated?.(created);
      onClose();
    } catch (err) {
      toast.error(err.message || 'Zakaz yaratishda xato');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal modal-lg">
        {/* Header */}
        <div className="modal-header">
          <h2 className="modal-title">📋 Yangi Zakaz</h2>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>

        {/* Body */}
        <div className="modal-body">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 20px' }}>

            {/* ── Mijoz ma'lumotlari ─────────────────────────── */}
            <div style={{ gridColumn: '1 / -1' }}>
              <div style={{
                fontSize: 11, fontWeight: 700, textTransform: 'uppercase',
                letterSpacing: '0.06em', color: '#64748b', marginBottom: 12,
              }}>
                👤 Mijoz ma'lumotlari
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">
                Ismi-familiyasi <span className="required">*</span>
              </label>
              <input
                className={`form-input${errors.client_name ? ' error' : ''}`}
                placeholder="Alisher Karimov"
                value={form.client_name}
                onChange={(e) => set('client_name', e.target.value)}
              />
              {errors.client_name && <div className="form-error">{errors.client_name}</div>}
            </div>

            <div className="form-group">
              <label className="form-label">Telefon raqami</label>
              <input
                className="form-input"
                placeholder="+998 90 123 45 67"
                value={form.client_phone}
                onChange={(e) => set('client_phone', e.target.value)}
              />
            </div>

            {/* ── Televizor ma'lumotlari ─────────────────────── */}
            <div style={{ gridColumn: '1 / -1', marginTop: 8 }}>
              <div style={{
                fontSize: 11, fontWeight: 700, textTransform: 'uppercase',
                letterSpacing: '0.06em', color: '#64748b', marginBottom: 12,
              }}>
                📺 Televizor ma'lumotlari
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Brand</label>
              <select
                className="form-select"
                value={form.tv_brand}
                onChange={(e) => set('tv_brand', e.target.value)}
              >
                <option value="">— Brand tanlang —</option>
                {TV_BRANDS.map((b) => (
                  <option key={b} value={b === 'Boshqa' ? '' : b}>{b}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Model</label>
              <input
                className="form-input"
                placeholder="UA55TU8000"
                value={form.tv_model}
                onChange={(e) => set('tv_model', e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Diagonali</label>
              <input
                className="form-input"
                placeholder='55"'
                value={form.tv_diagonal}
                onChange={(e) => set('tv_diagonal', e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Seriya raqami</label>
              <input
                className="form-input"
                placeholder="0X4T3CXBA..."
                value={form.tv_serial_number}
                onChange={(e) => set('tv_serial_number', e.target.value)}
              />
            </div>

            {/* ── Nosozlik ───────────────────────────────────── */}
            <div style={{ gridColumn: '1 / -1', marginTop: 8 }}>
              <div style={{
                fontSize: 11, fontWeight: 700, textTransform: 'uppercase',
                letterSpacing: '0.06em', color: '#64748b', marginBottom: 12,
              }}>
                🔧 Zakaz tafsilotlari
              </div>
            </div>

            <div className="form-group" style={{ gridColumn: '1 / -1' }}>
              <label className="form-label">
                Nosozlik tavsifi <span className="required">*</span>
              </label>
              <textarea
                className={`form-textarea${errors.problem_description ? ' error' : ''}`}
                rows={3}
                placeholder="Ekran yonmayapti, ovoz bor lekin tasvir yo'q..."
                value={form.problem_description}
                onChange={(e) => set('problem_description', e.target.value)}
              />
              {errors.problem_description && (
                <div className="form-error">{errors.problem_description}</div>
              )}
            </div>

            <div className="form-group">
              <label className="form-label">Manba</label>
              <select
                className="form-select"
                value={form.source}
                onChange={(e) => set('source', e.target.value)}
              >
                {SOURCES.map(([val, label]) => (
                  <option key={val} value={val}>{label}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Taxminiy narx (so'm)</label>
              <input
                className="form-input"
                type="number"
                min="0"
                placeholder="150000"
                value={form.estimated_price}
                onChange={(e) => set('estimated_price', e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Usta tayinlash</label>
              <select
                className="form-select"
                value={form.master_id}
                onChange={(e) => set('master_id', e.target.value)}
              >
                <option value="">— Keyinroq tayinlanadi —</option>
                {masters.map((m) => (
                  <option key={m.id} value={m.id}>
                    {m.full_name} ({m.commission_percent}%)
                  </option>
                ))}
              </select>
            </div>

            {/* ── Deadline — MAJBURIY ────────────────────────── */}
            <div className="form-group">
              <label className="form-label">
                ⏰ Deadline (muddat) <span className="required">*</span>
              </label>
              <input
                className={`form-input${errors.deadline ? ' error' : ''}`}
                type="datetime-local"
                value={form.deadline}
                min={new Date().toISOString().slice(0, 16)}
                onChange={(e) => set('deadline', e.target.value)}
              />
              {errors.deadline ? (
                <div className="form-error">{errors.deadline}</div>
              ) : (
                <div style={{ fontSize: 11.5, color: '#94a3b8', marginTop: 4 }}>
                  Zakaz shu vaqtga qadar tayyor bo'lishi kerak
                </div>
              )}
            </div>

          </div>{/* /grid */}
        </div>

        {/* Footer */}
        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose} disabled={saving}>
            Bekor qilish
          </button>
          <button className="btn btn-primary" onClick={handleSave} disabled={saving}>
            {saving ? (
              <><span className="spinner" style={{ width: 14, height: 14 }} /> Saqlanmoqda...</>
            ) : (
              '✅ Zakaz yaratish'
            )}
          </button>
        </div>
      </div>
    </div>
  );
}

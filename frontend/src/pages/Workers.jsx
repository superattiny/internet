// ================================================
// Workers.jsx — Ishchilar boshqaruv sahifasi
// Qo'shish, ko'rish, tahrirlash, o'chirish
// Balans, qarz, lavozim
// ================================================

import { useEffect, useState } from 'react';
import workersApi from '@/api/workersApi';
import { usePageTitle } from '@/utils/hooks';
import { formatMoney, getInitials, ROLE_LABELS } from '@/utils/formatters';
import toast from 'react-hot-toast';

const ROLE_OPTIONS = [
  { value: 'master',   label: '👷 Usta (ta\'mirchi)' },
  { value: 'operator', label: '🖥️ Operator' },
];

// ── Yordamchi: Badge ──────────────────────────────────────────
function Badge({ children, color = 'blue' }) {
  const colors = {
    blue:   { bg: '#eff6ff', text: '#1d4ed8', border: '#bfdbfe' },
    green:  { bg: '#f0fdf4', text: '#15803d', border: '#bbf7d0' },
    red:    { bg: '#fef2f2', text: '#dc2626', border: '#fca5a5' },
    yellow: { bg: '#fefce8', text: '#a16207', border: '#fde68a' },
    purple: { bg: '#faf5ff', text: '#7e22ce', border: '#e9d5ff' },
    gray:   { bg: '#f8fafc', text: '#64748b', border: '#e2e8f0' },
  };
  const c = colors[color] || colors.blue;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '3px 9px', borderRadius: 20,
      fontSize: 12, fontWeight: 600,
      background: c.bg, color: c.text, border: `1px solid ${c.border}`,
    }}>
      {children}
    </span>
  );
}

// ── Modal komponent ────────────────────────────────────────────
function Modal({ isOpen, onClose, title, children, footer, size = 'md' }) {
  useEffect(() => {
    if (isOpen) document.body.style.overflow = 'hidden';
    else document.body.style.overflow = '';
    return () => { document.body.style.overflow = ''; };
  }, [isOpen]);

  if (!isOpen) return null;
  const maxW = { sm: 420, md: 560, lg: 720 }[size] || 560;

  return (
    <div
      onClick={(e) => e.target === e.currentTarget && onClose()}
      style={{
        position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)',
        backdropFilter: 'blur(4px)', zIndex: 100,
        display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 20,
      }}
    >
      <div style={{
        background: 'white', borderRadius: 16, width: '100%', maxWidth: maxW,
        maxHeight: '90vh', display: 'flex', flexDirection: 'column',
        boxShadow: '0 25px 50px rgba(0,0,0,0.25)',
        animation: 'slideUp .2s ease',
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '20px 24px 0',
        }}>
          <h3 style={{ fontSize: 17, fontWeight: 700, color: '#0f172a' }}>{title}</h3>
          <button onClick={onClose} style={{
            width: 30, height: 30, borderRadius: 8, border: 'none',
            background: '#f1f5f9', cursor: 'pointer', fontSize: 16,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>✕</button>
        </div>
        <div style={{ flex: 1, overflowY: 'auto', padding: '18px 24px' }}>
          {children}
        </div>
        {footer && (
          <div style={{
            display: 'flex', justifyContent: 'flex-end', gap: 10,
            padding: '14px 24px 20px', borderTop: '1px solid #f1f5f9',
          }}>
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}

// ── Forma maydoni ──────────────────────────────────────────────
function FormField({ label, required, error, children }) {
  return (
    <div style={{ marginBottom: 14 }}>
      <label style={{
        display: 'block', fontSize: 13, fontWeight: 600,
        color: '#374151', marginBottom: 5,
      }}>
        {label} {required && <span style={{ color: '#dc2626' }}>*</span>}
      </label>
      {children}
      {error && <div style={{ fontSize: 12, color: '#dc2626', marginTop: 3 }}>{error}</div>}
    </div>
  );
}

const inputStyle = (err) => ({
  width: '100%', padding: '9px 12px',
  border: `1.5px solid ${err ? '#dc2626' : '#e2e8f0'}`,
  borderRadius: 8, fontSize: 14, outline: 'none',
  fontFamily: 'inherit', color: '#1e293b', background: 'white',
  boxSizing: 'border-box',
});

// ── Yangi/Tahrirlash Modali ────────────────────────────────────
function WorkerFormModal({ isOpen, onClose, onSaved, editWorker }) {
  const isEdit = !!editWorker;
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState({});
  const [form, setForm] = useState({
    full_name: '', username: '', password: '',
    phone: '', role: 'master',
    commission_percent: 30, salary_rate: 0,
  });

  useEffect(() => {
    if (editWorker) {
      setForm({
        full_name: editWorker.full_name || '',
        username:  editWorker.username  || '',
        password:  '',
        phone:     editWorker.phone     || '',
        role:      editWorker.role      || 'master',
        commission_percent: editWorker.commission_percent || 0,
        salary_rate:        editWorker.salary_rate        || 0,
      });
    } else {
      setForm({ full_name:'', username:'', password:'', phone:'', role:'master', commission_percent:30, salary_rate:0 });
    }
    setErrors({});
  }, [editWorker, isOpen]);

  const set = (k, v) => {
    setForm(p => ({ ...p, [k]: v }));
    if (errors[k]) setErrors(p => ({ ...p, [k]: '' }));
  };

  const validate = () => {
    const e = {};
    if (!form.full_name.trim()) e.full_name = 'Ism kiritilishi shart';
    if (!isEdit && !form.username.trim()) e.username = 'Login kiritilishi shart';
    if (!isEdit && form.password.length < 4) e.password = 'Parol kamida 4 ta belgi';
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSave = async () => {
    if (!validate()) return;
    setSaving(true);
    try {
      if (isEdit) {
        const payload = {
          full_name: form.full_name,
          phone: form.phone || undefined,
          commission_percent: Number(form.commission_percent),
          salary_rate: Number(form.salary_rate),
        };
        await workersApi.update(editWorker.id, payload);
        toast.success('✅ Ishchi yangilandi');
      } else {
        await workersApi.create({
          full_name:          form.full_name.trim(),
          username:           form.username.trim().toLowerCase(),
          password:           form.password,
          phone:              form.phone || undefined,
          role:               form.role,
          commission_percent: Number(form.commission_percent),
          salary_rate:        Number(form.salary_rate),
        });
        toast.success('✅ Ishchi qo\'shildi');
      }
      onSaved();
      onClose();
    } catch (err) {
      toast.error(err.message || 'Xato yuz berdi');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isEdit ? '✏️ Ishchini tahrirlash' : '➕ Yangi Ishchi'}
      size="md"
      footer={
        <>
          <button
            onClick={onClose}
            style={{ padding: '9px 18px', borderRadius: 8, border: '1.5px solid #e2e8f0', background: 'white', cursor: 'pointer', fontWeight: 600 }}
          >Bekor</button>
          <button
            onClick={handleSave}
            disabled={saving}
            style={{
              padding: '9px 20px', borderRadius: 8, border: 'none',
              background: '#2563eb', color: 'white', cursor: 'pointer',
              fontWeight: 600, opacity: saving ? 0.7 : 1,
              display: 'flex', alignItems: 'center', gap: 6,
            }}
          >
            {saving ? '⏳ Saqlanmoqda...' : '✅ Saqlash'}
          </button>
        </>
      }
    >
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 14px' }}>
        <div style={{ gridColumn: '1/-1' }}>
          <FormField label="Ismi-familiyasi" required error={errors.full_name}>
            <input
              style={inputStyle(errors.full_name)}
              placeholder="Sardor Toshmatov"
              value={form.full_name}
              onChange={e => set('full_name', e.target.value)}
            />
          </FormField>
        </div>

        {!isEdit && (
          <>
            <FormField label="Login (username)" required error={errors.username}>
              <input
                style={inputStyle(errors.username)}
                placeholder="sardor_usta"
                value={form.username}
                onChange={e => set('username', e.target.value)}
              />
            </FormField>
            <FormField label="Parol" required error={errors.password}>
              <input
                type="password"
                style={inputStyle(errors.password)}
                placeholder="Kamida 4 ta belgi"
                value={form.password}
                onChange={e => set('password', e.target.value)}
              />
            </FormField>
          </>
        )}

        <FormField label="Telefon raqami">
          <input
            style={inputStyle()}
            placeholder="+998 90 123 45 67"
            value={form.phone}
            onChange={e => set('phone', e.target.value)}
          />
        </FormField>

        {!isEdit && (
          <FormField label="Lavozimi" required>
            <select
              style={inputStyle()}
              value={form.role}
              onChange={e => set('role', e.target.value)}
            >
              {ROLE_OPTIONS.map(r => (
                <option key={r.value} value={r.value}>{r.label}</option>
              ))}
            </select>
          </FormField>
        )}

        <FormField label="Komisyon foizi (%)">
          <input
            type="number" min="0" max="100"
            style={inputStyle()}
            placeholder="30"
            value={form.commission_percent}
            onChange={e => set('commission_percent', e.target.value)}
          />
        </FormField>

        <FormField label="Oylik stavka (so'm)">
          <input
            type="number" min="0"
            style={inputStyle()}
            placeholder="1500000"
            value={form.salary_rate}
            onChange={e => set('salary_rate', e.target.value)}
          />
        </FormField>
      </div>

      {!isEdit && (
        <div style={{
          padding: '10px 14px', background: '#fffbeb',
          border: '1px solid #fde68a', borderRadius: 8, marginTop: 8,
          fontSize: 12.5, color: '#92400e',
        }}>
          💡 Komisyon foizi — har bir zakaz topshirilganda ustaning balansiga avtomatik qo'shiladi.
          Masalan: 30% = 300,000 so'mlik zakazdan 90,000 so'm usta balansiga tushadi.
        </div>
      )}
    </Modal>
  );
}

// ── Ish haqi to'lash modali ────────────────────────────────────
function SalaryModal({ isOpen, onClose, worker, onPaid }) {
  const [amount, setAmount]   = useState('');
  const [method, setMethod]   = useState('cash');
  const [note,   setNote]     = useState('');
  const [saving, setSaving]   = useState(false);

  useEffect(() => {
    if (worker) setAmount(String(Math.floor(worker.balance || 0)));
    else setAmount('');
    setNote('');
    setMethod('cash');
  }, [worker, isOpen]);

  const handlePay = async () => {
    const amt = parseFloat(amount);
    if (!amt || amt <= 0) { toast.error('Summa kiriting!'); return; }
    if (amt > (worker?.balance || 0)) { toast.error('Balans yetarli emas!'); return; }
    setSaving(true);
    try {
      await workersApi.paySalary(worker.id, amt, method, note);
      toast.success(`✅ ${formatMoney(amt)} to'landi`);
      onPaid();
      onClose();
    } catch (err) {
      toast.error(err.message || 'Xato');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen} onClose={onClose}
      title={`💳 Ish haqi — ${worker?.full_name || ''}`}
      size="sm"
      footer={
        <>
          <button onClick={onClose} style={{ padding: '9px 18px', borderRadius: 8, border: '1.5px solid #e2e8f0', background: 'white', cursor: 'pointer', fontWeight: 600 }}>
            Bekor
          </button>
          <button onClick={handlePay} disabled={saving} style={{
            padding: '9px 20px', borderRadius: 8, border: 'none',
            background: '#16a34a', color: 'white', cursor: 'pointer', fontWeight: 600, opacity: saving ? 0.7 : 1,
          }}>
            {saving ? '⏳...' : '💳 To\'lov'}
          </button>
        </>
      }
    >
      <div style={{
        padding: '12px 14px', background: '#f0fdf4',
        border: '1px solid #bbf7d0', borderRadius: 10, marginBottom: 16,
      }}>
        <div style={{ fontSize: 12, color: '#64748b' }}>Joriy balans:</div>
        <div style={{ fontSize: 22, fontWeight: 800, color: '#16a34a' }}>
          {formatMoney(worker?.balance || 0)}
        </div>
      </div>
      <FormField label="To'lov summasi (so'm)" required>
        <input
          type="number" min="0"
          style={inputStyle()}
          value={amount}
          onChange={e => setAmount(e.target.value)}
        />
      </FormField>
      <FormField label="To'lov usuli">
        <select style={inputStyle()} value={method} onChange={e => setMethod(e.target.value)}>
          <option value="cash">💵 Naqd pul</option>
          <option value="card">💳 Plastik karta</option>
          <option value="transfer">🏦 Bank o'tkazmasi</option>
        </select>
      </FormField>
      <FormField label="Izoh">
        <input
          style={inputStyle()}
          placeholder="Iyun oyi ish haqi..."
          value={note}
          onChange={e => setNote(e.target.value)}
        />
      </FormField>
    </Modal>
  );
}

// ── O'chirish tasdiqlash modali ────────────────────────────────
function DeleteModal({ isOpen, onClose, worker, onDeleted }) {
  const [saving, setSaving] = useState(false);
  const handleDelete = async () => {
    setSaving(true);
    try {
      await workersApi.deactivate(worker.id);
      toast.success(`🔒 ${worker.full_name} bloklandi`);
      onDeleted();
      onClose();
    } catch (err) {
      toast.error(err.message || 'Xato');
    } finally {
      setSaving(false);
    }
  };
  return (
    <Modal isOpen={isOpen} onClose={onClose} title="⚠️ Ishchini bloklash" size="sm"
      footer={
        <>
          <button onClick={onClose} style={{ padding: '9px 18px', borderRadius: 8, border: '1.5px solid #e2e8f0', background: 'white', cursor: 'pointer', fontWeight: 600 }}>
            Bekor
          </button>
          <button onClick={handleDelete} disabled={saving} style={{
            padding: '9px 20px', borderRadius: 8, border: 'none',
            background: '#dc2626', color: 'white', cursor: 'pointer', fontWeight: 600,
          }}>
            {saving ? '⏳...' : '🔒 Bloklash'}
          </button>
        </>
      }
    >
      <div style={{ textAlign: 'center', padding: '10px 0' }}>
        <div style={{ fontSize: 48, marginBottom: 12 }}>⚠️</div>
        <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 8 }}>
          {worker?.full_name} ni bloklashni xohlaysizmi?
        </div>
        <div style={{ fontSize: 13, color: '#64748b', lineHeight: 1.6 }}>
          Bloklangan ishchi tizimga kira olmaydi.
          Ma'lumotlari va tarixi saqlanib qoladi.
          Keyinchalik qayta faollashtirish mumkin.
        </div>
      </div>
    </Modal>
  );
}

// ================================================================
//  ASOSIY WORKERS SAHIFASI
// ================================================================
export default function Workers() {
  usePageTitle('Ishchilar');

  const [workers,     setWorkers]     = useState([]);
  const [loading,     setLoading]     = useState(true);
  const [search,      setSearch]      = useState('');
  const [filterRole,  setFilterRole]  = useState('all');

  // Modallar
  const [showForm,    setShowForm]    = useState(false);
  const [editWorker,  setEditWorker]  = useState(null);
  const [salaryWorker,setSalaryWorker]= useState(null);
  const [deleteWorker,setDeleteWorker]= useState(null);

  // ── Yuklash ────────────────────────────────────────────────
  const load = async () => {
    setLoading(true);
    try {
      const res = await workersApi.getList({ page_size: 100 });
      setWorkers(res.items || []);
    } catch (err) {
      toast.error('Ishchilar yuklanmadi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  // ── Filtr ──────────────────────────────────────────────────
  const filtered = workers.filter(w => {
    const matchSearch =
      !search ||
      w.full_name.toLowerCase().includes(search.toLowerCase()) ||
      (w.phone || '').includes(search) ||
      w.username.toLowerCase().includes(search.toLowerCase());
    const matchRole =
      filterRole === 'all' || w.role === filterRole;
    return matchSearch && matchRole;
  });

  // ── Statistika ─────────────────────────────────────────────
  const stats = {
    total:      workers.length,
    masters:    workers.filter(w => w.role === 'master').length,
    operators:  workers.filter(w => w.role === 'operator').length,
    totalBalance: workers.reduce((s, w) => s + (w.balance || 0), 0),
  };

  return (
    <div>
      {/* ── Stat kartalar ─────────────────────────────────── */}
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))',
        gap: 14, marginBottom: 20,
      }}>
        {[
          { icon: '👥', label: 'Jami ishchilar', value: stats.total, color: '#2563eb' },
          { icon: '👷', label: 'Ustalar',         value: stats.masters,   color: '#d97706' },
          { icon: '🖥️', label: 'Operatorlar',     value: stats.operators, color: '#0891b2' },
          { icon: '💰', label: 'Umumiy balans',   value: formatMoney(stats.totalBalance), color: '#16a34a', small: true },
        ].map((s, i) => (
          <div key={i} style={{
            background: 'white', border: '1px solid #f1f5f9', borderRadius: 12,
            padding: '16px 18px', display: 'flex', alignItems: 'center', gap: 12,
            boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
          }}>
            <div style={{
              width: 42, height: 42, borderRadius: 10, fontSize: 20,
              background: `${s.color}18`, display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>{s.icon}</div>
            <div>
              <div style={{ fontSize: 12, color: '#64748b', fontWeight: 500 }}>{s.label}</div>
              <div style={{ fontSize: s.small ? 16 : 24, fontWeight: 800, color: s.color, lineHeight: 1.1 }}>
                {s.value}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* ── Toolbar ───────────────────────────────────────── */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        flexWrap: 'wrap', gap: 12, marginBottom: 16,
      }}>
        {/* Qidiruv */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          background: 'white', border: '1.5px solid #e2e8f0',
          borderRadius: 10, padding: '8px 12px', maxWidth: 280, flex: 1,
        }}>
          <span>🔍</span>
          <input
            placeholder="Ism, login yoki telefon..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            style={{ border: 'none', outline: 'none', fontSize: 13.5, color: '#374151', flex: 1, background: 'transparent' }}
          />
        </div>

        {/* Rol filtri */}
        <div style={{ display: 'flex', gap: 6 }}>
          {[
            { value: 'all',      label: 'Barchasi' },
            { value: 'master',   label: '👷 Ustalar' },
            { value: 'operator', label: '🖥️ Operatorlar' },
          ].map(f => (
            <button
              key={f.value}
              onClick={() => setFilterRole(f.value)}
              style={{
                padding: '7px 14px', borderRadius: 20, fontSize: 12.5,
                fontWeight: 600, cursor: 'pointer', whiteSpace: 'nowrap',
                border: `1.5px solid ${filterRole === f.value ? '#2563eb' : '#e2e8f0'}`,
                background: filterRole === f.value ? '#2563eb' : 'white',
                color: filterRole === f.value ? 'white' : '#64748b',
              }}
            >
              {f.label}
            </button>
          ))}
        </div>

        {/* Yangi tugma */}
        <button
          onClick={() => { setEditWorker(null); setShowForm(true); }}
          style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '10px 18px', borderRadius: 10,
            background: '#2563eb', color: 'white', border: 'none',
            fontWeight: 700, fontSize: 14, cursor: 'pointer',
          }}
        >
          ＋ Yangi Ishchi
        </button>
      </div>

      {/* ── Jadval ────────────────────────────────────────── */}
      <div style={{
        background: 'white', border: '1px solid #f1f5f9',
        borderRadius: 14, overflow: 'hidden',
        boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
      }}>
        {/* Jadval sarlavhasi */}
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '16px 20px 14px', borderBottom: '1px solid #f8fafc',
        }}>
          <span style={{ fontSize: 15, fontWeight: 700, color: '#0f172a' }}>
            👨‍🔧 Ishchilar jadvali
          </span>
          <span style={{ fontSize: 13, color: '#94a3b8' }}>
            Jami: <b style={{ color: '#0f172a' }}>{filtered.length}</b> ta
          </span>
        </div>

        {loading ? (
          <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', padding: 60, color: '#94a3b8', gap: 10 }}>
            <div style={{
              width: 24, height: 24, border: '3px solid #e2e8f0',
              borderTopColor: '#2563eb', borderRadius: '50%',
              animation: 'spin .7s linear infinite',
            }} />
            Yuklanmoqda...
          </div>
        ) : filtered.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 60, color: '#94a3b8' }}>
            <div style={{ fontSize: 48, marginBottom: 12, opacity: 0.5 }}>👷</div>
            <div style={{ fontSize: 15, fontWeight: 600, color: '#64748b', marginBottom: 8 }}>
              Ishchilar topilmadi
            </div>
            <button
              onClick={() => { setEditWorker(null); setShowForm(true); }}
              style={{
                padding: '9px 18px', borderRadius: 10, background: '#2563eb',
                color: 'white', border: 'none', cursor: 'pointer', fontWeight: 600,
              }}
            >
              ＋ Birinchi ishchini qo'shing
            </button>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13.5 }}>
              <thead>
                <tr style={{ background: '#f8fafc', borderBottom: '1px solid #e2e8f0' }}>
                  {['Ishchi', 'Lavozimi', 'Telefon', 'Balans', 'Qarzi', 'Komisyon', 'Holat', 'Amallar'].map(h => (
                    <th key={h} style={{
                      padding: '10px 14px', textAlign: 'left',
                      fontSize: 11, fontWeight: 700, textTransform: 'uppercase',
                      letterSpacing: '0.05em', color: '#64748b', whiteSpace: 'nowrap',
                    }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {filtered.map(worker => (
                  <WorkerRow
                    key={worker.id}
                    worker={worker}
                    onEdit={() => { setEditWorker(worker); setShowForm(true); }}
                    onSalary={() => setSalaryWorker(worker)}
                    onDelete={() => setDeleteWorker(worker)}
                    onActivate={async () => {
                      try {
                        await workersApi.activate(worker.id);
                        toast.success('✅ Faollashtirildi');
                        load();
                      } catch (e) { toast.error(e.message); }
                    }}
                  />
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* ── Modallar ──────────────────────────────────────── */}
      <WorkerFormModal
        isOpen={showForm}
        onClose={() => { setShowForm(false); setEditWorker(null); }}
        onSaved={load}
        editWorker={editWorker}
      />
      <SalaryModal
        isOpen={!!salaryWorker}
        onClose={() => setSalaryWorker(null)}
        worker={salaryWorker}
        onPaid={load}
      />
      <DeleteModal
        isOpen={!!deleteWorker}
        onClose={() => setDeleteWorker(null)}
        worker={deleteWorker}
        onDeleted={load}
      />

      <style>{`
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes slideUp { from { transform: translateY(16px); opacity:0; } to { transform: translateY(0); opacity:1; } }
        tbody tr:hover { background: #fafafa; }
      `}</style>
    </div>
  );
}

// ── Bitta qator ────────────────────────────────────────────────
function WorkerRow({ worker, onEdit, onSalary, onDelete, onActivate }) {
  const initials = getInitials(worker.full_name);
  const roleColor = worker.role === 'master' ? 'yellow' : 'blue';
  const roleLabel = ROLE_LABELS[worker.role] || worker.role;

  return (
    <tr style={{ borderBottom: '1px solid #f8fafc', transition: 'background .15s' }}>
      {/* Ishchi */}
      <td style={{ padding: '13px 14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 36, height: 36, borderRadius: '50%',
            background: 'linear-gradient(135deg, #2563eb, #1d4ed8)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 13, fontWeight: 700, color: 'white', flexShrink: 0,
          }}>{initials}</div>
          <div>
            <div style={{ fontWeight: 600, fontSize: 13.5, color: '#0f172a' }}>
              {worker.full_name}
            </div>
            <div style={{ fontSize: 11.5, color: '#94a3b8' }}>@{worker.username}</div>
          </div>
        </div>
      </td>

      {/* Lavozim */}
      <td style={{ padding: '13px 14px' }}>
        <Badge color={roleColor}>
          {worker.role === 'master' ? '👷' : '🖥️'} {roleLabel}
        </Badge>
      </td>

      {/* Telefon */}
      <td style={{ padding: '13px 14px', fontSize: 13, color: '#374151', fontFamily: 'monospace' }}>
        {worker.phone || <span style={{ color: '#cbd5e1' }}>—</span>}
      </td>

      {/* Balans */}
      <td style={{ padding: '13px 14px' }}>
        <span style={{
          fontWeight: 700, fontSize: 13.5,
          color: (worker.balance || 0) > 0 ? '#16a34a' : '#94a3b8',
          fontFamily: 'monospace',
        }}>
          {formatMoney(worker.balance || 0)}
        </span>
      </td>

      {/* Qarzi */}
      <td style={{ padding: '13px 14px' }}>
        <span style={{
          fontWeight: 600, fontSize: 13,
          color: (worker.debt || 0) > 0 ? '#dc2626' : '#94a3b8',
          fontFamily: 'monospace',
        }}>
          {(worker.debt || 0) > 0 ? formatMoney(worker.debt) : <span style={{ color: '#cbd5e1' }}>—</span>}
        </span>
      </td>

      {/* Komisyon */}
      <td style={{ padding: '13px 14px' }}>
        {(worker.commission_percent || 0) > 0 ? (
          <Badge color="purple">{worker.commission_percent}%</Badge>
        ) : (
          <span style={{ color: '#cbd5e1' }}>—</span>
        )}
      </td>

      {/* Holat */}
      <td style={{ padding: '13px 14px' }}>
        <Badge color={worker.is_active ? 'green' : 'red'}>
          {worker.is_active ? '✅ Faol' : '🔒 Bloklangan'}
        </Badge>
      </td>

      {/* Amallar */}
      <td style={{ padding: '13px 14px' }}>
        <div style={{ display: 'flex', gap: 6 }}>
          {/* Ish haqi */}
          <button
            onClick={onSalary}
            disabled={!worker.is_active || !worker.balance}
            title="Ish haqi to'lash"
            style={{
              padding: '5px 10px', borderRadius: 7, border: 'none',
              background: '#dcfce7', color: '#16a34a',
              cursor: (!worker.is_active || !worker.balance) ? 'not-allowed' : 'pointer',
              fontWeight: 600, fontSize: 12,
              opacity: (!worker.is_active || !worker.balance) ? 0.4 : 1,
            }}
          >💳</button>

          {/* Tahrirlash */}
          <button
            onClick={onEdit}
            title="Tahrirlash"
            style={{
              padding: '5px 10px', borderRadius: 7, border: 'none',
              background: '#eff6ff', color: '#2563eb',
              cursor: 'pointer', fontWeight: 600, fontSize: 12,
            }}
          >✏️</button>

          {/* O'chirish / Faollashtirish */}
          {worker.is_active ? (
            <button
              onClick={onDelete}
              title="Bloklash"
              style={{
                padding: '5px 10px', borderRadius: 7, border: 'none',
                background: '#fef2f2', color: '#dc2626',
                cursor: 'pointer', fontWeight: 600, fontSize: 12,
              }}
            >🗑️</button>
          ) : (
            <button
              onClick={onActivate}
              title="Faollashtirish"
              style={{
                padding: '5px 10px', borderRadius: 7, border: 'none',
                background: '#f0fdf4', color: '#16a34a',
                cursor: 'pointer', fontWeight: 600, fontSize: 12,
              }}
            >🔓</button>
          )}
        </div>
      </td>
    </tr>
  );
}

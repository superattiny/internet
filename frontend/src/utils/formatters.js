// ================================================
// formatters.js — Formatlash yordamchi funksiyalari
// Sana, pul, status matnlari
// ================================================

import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import 'dayjs/locale/uz';

dayjs.extend(relativeTime);
dayjs.locale('uz');

// ================================================================
//  PUL FORMATLASH
// ================================================================

/**
 * Sonni pul formatida ko'rsatadi
 * formatMoney(1500000) → "1 500 000 so'm"
 */
export const formatMoney = (amount, currency = "so'm") => {
  if (amount == null || isNaN(amount)) return `0 ${currency}`;
  return (
    Number(amount)
      .toLocaleString('uz-UZ', { maximumFractionDigits: 0 })
      .replace(/,/g, ' ') +
    ` ${currency}`
  );
};

/**
 * Qisqa format: 1500000 → "1.5M" yoki "1 500 000"
 */
export const formatMoneyShort = (amount) => {
  if (!amount) return "0";
  if (amount >= 1_000_000)
    return `${(amount / 1_000_000).toFixed(1)}M so'm`;
  if (amount >= 1_000)
    return `${(amount / 1_000).toFixed(0)}K so'm`;
  return `${amount} so'm`;
};

// ================================================================
//  SANA VA VAQT FORMATLASH
// ================================================================

/**
 * Standart sana-vaqt formati
 * formatDate("2025-06-15T14:30:00") → "15-iyun 2025, 14:30"
 */
export const formatDate = (dateStr) => {
  if (!dateStr) return '—';
  const months = [
    'yan', 'fev', 'mar', 'apr', 'may', 'iyun',
    'iyul', 'avg', 'sen', 'okt', 'noy', 'dek',
  ];
  const d = dayjs(dateStr);
  if (!d.isValid()) return '—';
  return `${d.date()}-${months[d.month()]} ${d.year()}, ${d.format('HH:mm')}`;
};

/**
 * Faqat sana
 * formatDateOnly("2025-06-15T14:30:00") → "15.06.2025"
 */
export const formatDateOnly = (dateStr) => {
  if (!dateStr) return '—';
  return dayjs(dateStr).format('DD.MM.YYYY');
};

/**
 * Qancha vaqt avval / keyin
 * formatRelative("2025-06-14T10:00:00") → "2 soat avval"
 */
export const formatRelative = (dateStr) => {
  if (!dateStr) return '—';
  return dayjs(dateStr).fromNow();
};

/**
 * Deadline uchun maxsus format — qolgan vaqtni ko'rsatadi
 * formatDeadline(iso, hours_remaining)
 * → { label, className, icon, isOverdue }
 */
export const formatDeadline = (deadlineStr, hoursRemaining) => {
  if (!deadlineStr) return { label: '—', className: '', icon: '', isOverdue: false };

  const h = hoursRemaining ?? 999;
  const isOverdue = h < 0;
  const absH = Math.abs(h);

  let label, className, icon;

  if (isOverdue) {
    const overdueH = absH;
    if (overdueH < 1)
      label = `${Math.round(overdueH * 60)} daq. o'tdi`;
    else if (overdueH < 24)
      label = `${overdueH.toFixed(0)} soat o'tdi`;
    else
      label = `${(overdueH / 24).toFixed(0)} kun o'tdi`;
    className = 'deadline-overdue';
    icon = '❌';
  } else if (h <= 2) {
    label = `${Math.round(h * 60)} daqiqa`;
    className = 'deadline-critical';
    icon = '🔴';
  } else if (h <= 24) {
    label = `${h.toFixed(0)} soat`;
    className = 'deadline-warning';
    icon = '⚠️';
  } else {
    const days = h / 24;
    label = days >= 1 ? `${days.toFixed(0)} kun` : `${h.toFixed(0)} soat`;
    className = 'deadline-ok';
    icon = '✅';
  }

  return { label, className, icon, isOverdue };
};

// ================================================================
//  STATUS TARJIMALARI
// ================================================================

export const ORDER_STATUS_LABELS = {
  new:         'Yangi',
  accepted:    'Qabul qilindi',
  diagnosing:  'Diagnostika',
  waiting:     'Kutilmoqda',
  on_the_way:  'Yo\'lda',
  in_repair:   'Ta\'mirda',
  done:        'Tayyor',
  delivered:   'Topshirildi',
  cancelled:   'Bekor qilindi',
};

export const ORDER_STATUS_COLORS = {
  new:         'badge-new',
  accepted:    'badge-accepted',
  diagnosing:  'badge-diagnosing',
  waiting:     'badge-waiting',
  on_the_way:  'badge-on_the_way',
  in_repair:   'badge-in_repair',
  done:        'badge-done',
  delivered:   'badge-delivered',
  cancelled:   'badge-cancelled',
};

export const ORDER_STATUS_ICONS = {
  new:         '🆕',
  accepted:    '✅',
  diagnosing:  '🔍',
  waiting:     '⏳',
  on_the_way:  '🚗',
  in_repair:   '🔧',
  done:        '✔️',
  delivered:   '🎉',
  cancelled:   '❌',
};

export const ROLE_LABELS = {
  admin:    'Admin',
  operator: 'Operator',
  master:   'Usta',
};

export const ROLE_COLORS = {
  admin:    'badge-admin',
  operator: 'badge-operator',
  master:   'badge-master',
};

export const PAYMENT_METHOD_LABELS = {
  cash:     'Naqd',
  card:     'Karta',
  transfer: "O'tkazma",
};

export const ORDER_SOURCE_LABELS = {
  walk_in:   'Bevosita',
  phone:     'Telefon',
  telegram:  'Telegram',
  instagram: 'Instagram',
  other:     'Boshqa',
};

// ================================================================
//  STATUS O'TISH (TRANSITIONS) — Frontend uchun
// ================================================================

export const ALLOWED_TRANSITIONS = {
  new:        ['accepted', 'cancelled'],
  accepted:   ['diagnosing', 'on_the_way', 'cancelled'],
  diagnosing: ['waiting', 'in_repair', 'on_the_way', 'cancelled'],
  waiting:    ['in_repair', 'on_the_way', 'cancelled'],
  on_the_way: ['in_repair', 'accepted', 'diagnosing', 'cancelled'],
  in_repair:  ['done', 'waiting', 'on_the_way', 'cancelled'],
  done:       ['delivered', 'cancelled'],
  delivered:  [],
  cancelled:  [],
};

/**
 * Berilgan statusdan o'tish mumkin bo'lgan statuslar ro'yxati
 */
export const getAllowedNextStatuses = (currentStatus) => {
  return (ALLOWED_TRANSITIONS[currentStatus] || []).map((s) => ({
    value: s,
    label: ORDER_STATUS_LABELS[s],
    icon:  ORDER_STATUS_ICONS[s],
  }));
};

// ================================================================
//  QISQARTIRISH
// ================================================================

/**
 * Uzun matnni qisqartiradi
 * truncate("Ekran yonmayapti...", 30) → "Ekran yonmayapti..."
 */
export const truncate = (str, maxLen = 40) => {
  if (!str) return '—';
  return str.length > maxLen ? str.slice(0, maxLen) + '…' : str;
};

/**
 * Ism-familiyadan bosh harflarni oladi
 * getInitials("Sardor Toshmatov") → "ST"
 */
export const getInitials = (name) => {
  if (!name) return '?';
  return name
    .split(' ')
    .slice(0, 2)
    .map((w) => w[0]?.toUpperCase() || '')
    .join('');
};

/**
 * TV ma'lumotlarini bitta qatorda chiqaradi
 * formatTvInfo({ tv_brand, tv_model, tv_diagonal }) → "Samsung UA55TU8000 55\""
 */
export const formatTvInfo = (order) => {
  const parts = [order?.tv_brand, order?.tv_model, order?.tv_diagonal].filter(Boolean);
  return parts.join(' ') || 'TV ma\'lumoti yo\'q';
};

/**
 * Telefon raqamni formatlaydi
 * formatPhone("+998901234567") → "+998 90 123 45 67"
 */
export const formatPhone = (phone) => {
  if (!phone) return '—';
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.startsWith('998') && cleaned.length === 12) {
    return `+998 ${cleaned.slice(3, 5)} ${cleaned.slice(5, 8)} ${cleaned.slice(8, 10)} ${cleaned.slice(10)}`;
  }
  return phone;
};

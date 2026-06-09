// ================================================
// hooks.js — Qayta ishlatiladigan React Hook'lar
// ================================================

import { useState, useEffect, useCallback, useRef } from 'react';

// ── Debounce hook (qidiruv uchun) ───────────────────────────────
export const useDebounce = (value, delay = 400) => {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);
  return debounced;
};

// ── Modal holati hook ───────────────────────────────────────────
export const useModal = (initial = false) => {
  const [isOpen, setIsOpen] = useState(initial);
  const [data, setData] = useState(null);

  const open  = useCallback((payload = null) => { setData(payload); setIsOpen(true);  }, []);
  const close = useCallback(() => { setIsOpen(false); setData(null); }, []);

  // ESC tugmasi bilan yopish
  useEffect(() => {
    if (!isOpen) return;
    const handler = (e) => { if (e.key === 'Escape') close(); };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [isOpen, close]);

  return { isOpen, data, open, close };
};

// ── Polling hook (avtomatik yangilash) ──────────────────────────
export const usePolling = (fn, intervalMs = 30000, enabled = true) => {
  useEffect(() => {
    if (!enabled) return;
    fn(); // Darhol chaqirish
    const id = setInterval(fn, intervalMs);
    return () => clearInterval(id);
  }, [fn, intervalMs, enabled]);
};

// ── Click outside hook (dropdown/modal yopish) ─────────────────
export const useClickOutside = (handler) => {
  const ref = useRef(null);
  useEffect(() => {
    const listener = (e) => {
      if (!ref.current || ref.current.contains(e.target)) return;
      handler();
    };
    document.addEventListener('mousedown', listener);
    return () => document.removeEventListener('mousedown', listener);
  }, [handler]);
  return ref;
};

// ── Local storage hook ──────────────────────────────────────────
export const useLocalStorage = (key, initialValue) => {
  const [value, setValue] = useState(() => {
    try {
      const item = localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch { return initialValue; }
  });

  const setStored = useCallback((newValue) => {
    try {
      setValue(newValue);
      localStorage.setItem(key, JSON.stringify(newValue));
    } catch {}
  }, [key]);

  return [value, setStored];
};

// ── Sahifa sarlavhasi hook ───────────────────────────────────────
export const usePageTitle = (title) => {
  useEffect(() => {
    document.title = title ? `${title} — TV CRM` : 'TV CRM';
    return () => { document.title = 'TV CRM'; };
  }, [title]);
};

// ── Async holat hook (loading/error/data) ───────────────────────
export const useAsync = (asyncFn, immediate = true) => {
  const [state, setState] = useState({
    data:      null,
    isLoading: immediate,
    error:     null,
  });

  const execute = useCallback(async (...args) => {
    setState((s) => ({ ...s, isLoading: true, error: null }));
    try {
      const data = await asyncFn(...args);
      setState({ data, isLoading: false, error: null });
      return data;
    } catch (err) {
      setState((s) => ({ ...s, isLoading: false, error: err.message }));
      throw err;
    }
  }, [asyncFn]);

  useEffect(() => {
    if (immediate) execute();
  }, []); // eslint-disable-line

  return { ...state, execute };
};

// ================================================
// Button.jsx — Qayta ishlatiladigan tugma komponenti
// ================================================

export default function Button({
  children,
  variant  = 'primary',  // primary | secondary | danger | success | ghost
  size     = 'md',       // sm | md | lg | icon
  loading  = false,
  disabled = false,
  icon,
  onClick,
  type     = 'button',
  className = '',
  style,
  title,
  ...rest
}) {
  return (
    <button
      type={type}
      className={`btn btn-${variant} btn-${size} ${className}`}
      disabled={disabled || loading}
      onClick={onClick}
      title={title}
      style={style}
      {...rest}
    >
      {loading ? (
        <>
          <span className="spinner" style={{ width: 14, height: 14 }} />
          {children && <span>Yuklanmoqda...</span>}
        </>
      ) : (
        <>
          {icon && <span>{icon}</span>}
          {children}
        </>
      )}
    </button>
  );
}

// ── Icon tugma ───────────────────────────────────────────────────
export function IconButton({ icon, onClick, title, variant = 'ghost', disabled }) {
  return (
    <button
      type="button"
      className={`btn btn-${variant} btn-icon`}
      onClick={onClick}
      title={title}
      disabled={disabled}
    >
      {icon}
    </button>
  );
}

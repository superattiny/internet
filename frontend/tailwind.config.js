// tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{js,jsx,ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        // Asosiy brend ranglar
        primary: {
          50:  '#eff6ff',
          100: '#dbeafe',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          900: '#1e3a8a',
        },
        // Sidebar qoʻngʻir-koʻk
        sidebar: {
          bg:     '#0f172a',
          hover:  '#1e293b',
          active: '#1d4ed8',
          text:   '#94a3b8',
          light:  '#f1f5f9',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        card: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
        modal: '0 25px 50px -12px rgb(0 0 0 / 0.25)',
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'slide-in':   'slideIn 0.2s ease-out',
        'fade-in':    'fadeIn 0.15s ease-out',
      },
      keyframes: {
        slideIn: {
          '0%':   { transform: 'translateX(-10px)', opacity: '0' },
          '100%': { transform: 'translateX(0)',     opacity: '1' },
        },
        fadeIn: {
          '0%':   { opacity: '0', transform: 'scale(0.97)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
      },
    },
  },
  plugins: [],
};

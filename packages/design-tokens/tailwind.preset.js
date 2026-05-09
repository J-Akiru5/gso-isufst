// @gso/design-tokens — Tailwind CSS Preset
// Extend your tailwind.config.ts with: presets: [require('@gso/design-tokens/tailwind')]

/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#003d62',
          light: '#d0e7f5',
          dark: '#002744',
        },
        secondary: {
          DEFAULT: '#2a80af',
          dark: '#1d6a94',
        },
        institutional: '#142d55',
        vivid: '#0352bc',
        brand: {
          dark: '#0f0d0e',
        },
        status: {
          pending: '#f59e0b',
          'in-progress': '#2a80af',
          completed: '#16a34a',
          rejected: '#dc2626',
          urgent: '#9333ea',
          closed: '#64748b',
        },
      },
      fontFamily: {
        sans: ['Inter', 'Arial', 'sans-serif'],
      },
      borderRadius: {
        DEFAULT: '0.5rem',
      },
      boxShadow: {
        'glow-primary': '0 0 20px rgba(0, 61, 98, 0.3)',
        'glow-secondary': '0 0 15px rgba(42, 128, 175, 0.25)',
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'pulse-soft': 'pulseSoft 2s ease-in-out infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        pulseSoft: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.7' },
        },
      },
    },
  },
}

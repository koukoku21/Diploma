import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: '#c9a96e',
        'brand-dark': '#b8924a',
        'bg-primary': '#0a0a0f',
        'bg-secondary': '#111118',
        'bg-tertiary': '#16161f',
        'text-primary': '#f0ede8',
        'text-secondary': '#9b9690',
      },
      fontFamily: {
        sans: ['Mulish', 'sans-serif'],
        display: ['"Playfair Display"', 'serif'],
      },
      borderRadius: {
        pill: '100px',
      },
    },
  },
  plugins: [],
};

export default config;

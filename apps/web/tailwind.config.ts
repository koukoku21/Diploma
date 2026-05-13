import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: '#FF6B9D',
        'brand-dark': '#E85589',
      },
    },
  },
  plugins: [],
};

export default config;

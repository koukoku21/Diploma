import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./lib/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        bg: {
          primary: "#0A0A0F",
          secondary: "#111118",
          tertiary: "#16161F",
        },
        gold: "#C9A96E",
        rose: "#D4748A",
        text: {
          primary: "#F0EDE8",
          secondary: "#9B9690",
          tertiary: "#5A5750",
        },
        border: "rgba(255,255,255,0.07)",
        border2: "rgba(255,255,255,0.12)",
        success: "#1D9E75",
        error: "#D4748A",
      },
      borderRadius: {
        xl2: "20px",
      },
      boxShadow: {
        soft: "0 10px 30px rgba(0,0,0,0.18)",
      },
    },
  },
  plugins: [],
};

export default config;
import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "var(--color-background)",
        foreground: "var(--color-foreground)",
        surface: "var(--color-surface)",
        border: "var(--color-border)",
        "text-primary": "var(--color-text-primary)",
        "text-secondary": "var(--color-text-secondary)",
        accent: "var(--color-accent)",
        success: "var(--color-success)",
        warning: "var(--color-warning)",
        danger: "var(--color-danger)",
        // Brand colors from design system
        "brand-dark-bg": "#191A1D",
        "brand-dark-surface": "#2D3033",
        "brand-dark-border": "#363636",
        "brand-text-primary": "#F9F9F9",
        "brand-text-secondary": "#B7B7B7",
        "brand-accent": "#00F0FF",
        "brand-success": "#4ADE80",
        "brand-warning": "#FACC15",
        "brand-danger": "#F95757",
        "client-green": "#50B88A",
      },
      fontFamily: {
        sans: ["var(--font-sans)"],
      },
    },
  },
  plugins: [],
};

export default config;

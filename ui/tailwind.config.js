/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: 'var(--text-color-primary)',
        secondary: 'var(--text-color-secondary)',
      },
      borderColor: {
        box: 'var(--border-color-box)',
      },
      backgroundColor: {
        app: 'var(--background-color-app)',
        box: 'rgb(var(--background-color-box) / <alpha-value>)',
        inner: 'var(--background-color-inner)',
        inverted: 'rgb(var(--background-color-inverted) / <alpha-value>)',
      },
    },
  },
  plugins: [],
}


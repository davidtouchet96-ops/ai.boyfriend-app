/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        pink: { 400: '#f472b6', 500: '#ec4899', 600: '#db2777' },
        purple: { 500: '#a855f7', 600: '#9333ea' }
      }
    },
  },
  plugins: [],
}

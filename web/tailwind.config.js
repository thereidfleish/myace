const colors = require('tailwindcss/colors')

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        base: {
          dark: colors.gray,
        },
        primary: {
          // light: colors.violet,
          dark: colors.violet["400"],
          // dark: colors.green["400"],
        }
      }
    },
  },
  plugins: [require("daisyui")],
}

const colors = require('tailwindcss/colors')

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      // colors: {
      //   base: {
      //     dark: colors.gray,
      //   },
      //   primary: {
      //     // light: colors.violet,
      //     dark: colors.violet["400"],
      //     // dark: colors.green["400"],
      //   }
      // }
    },
  },
  daisyui: {
    themes: [
      {
        light: {
          ...require("daisyui/src/colors/themes")["[data-theme=light]"],
          "primary": "#8ad28a", // the lighter green from the logo
          "secondary": "#7ac07a", // the darker green from the logo
          "accent": "#f18d84" // generated from primary by https://giggster.com/guide/complementary-colors/
        },
        dark: {
          ...require("daisyui/src/colors/themes")["[data-theme=dark]"],
          "primary": "#7ac07a", // the darker green from the logo
          "secondary": "#8ad28a", // the lighter green from the logo
          "accent": "#e47669" // generated from primary by https://giggster.com/guide/complementary-colors/
        },
      },
    ],
  },
  plugins: [require("daisyui")],
}

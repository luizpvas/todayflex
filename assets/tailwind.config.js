module.exports = {
  purge: [
    "../lib/todayflex_web/templates/**/*.html.eex",
    "../lib/todayflex_web/views/**/*.ex",
  ],
  theme: {
    extend: {
    },
    fontFamily: {
      'sans': ['-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'Helvetica Neue', 'Ubuntu', 'sans-serif']
    }
  },
  variants: {
    textColor: ["responsive", "hover", "focus", "group-hover"],
    textDecoration: ["responsive", "hover", "focus", "active", "group-hover"],
  },
  plugins: [require("@tailwindcss/typography")],
};

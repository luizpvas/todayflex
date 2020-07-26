module.exports = {
  purge: [
    '../lib/todayflex_web/templates/**/*.html.eex',
    '../lib/todayflex_web/views/**/*.ex'
  ],
  theme: {
    extend: {},
  },
  variants: {},
  plugins: [
    require('@tailwindcss/typography')
  ],
}

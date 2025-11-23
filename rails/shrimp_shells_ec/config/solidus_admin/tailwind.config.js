const { execSync } = require('child_process')
const adminRoot = execSync('bundle show solidus_admin').toString().trim()
const solidusAdmin = require(`${adminRoot}/config/tailwind.config.js`)

module.exports = {
  // Read how to use TailwindCSS presets: https://tailwindcss.com/docs/presets.
  presets: [solidusAdmin],

  content: [
    // Include paths coming from SolidusAdmin.
    ...solidusAdmin.content,

    // Include paths to your own components.
    `${__dirname}/../../app/components/admin/**/*`,
  ],
}

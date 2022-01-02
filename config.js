require('dotenv').config()

module.exports = {
  title: process.env.BOOKIT_TITLE,
  domain: process.env.BOOKIT_DOMAIN,
  timezone: process.env.BOOKIT_TZ,
  password: process.env.BOOKIT_PASSWORD,
  company: process.env.BOOKIT_COMPANY,
  product: process.env.BOOKIT_PRODUCT,
  defaultnames: process.env.BOOKIT_DEFAULT_NAMES.split('|'),
  availableTags: process.env.BOOKIT_TAGS.split('|')
}

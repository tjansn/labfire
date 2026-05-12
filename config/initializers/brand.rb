Rails.application.configure do
  config.x.brand.name = ENV.fetch("APP_NAME", "Labfire")
  config.x.brand.repository_url = ENV.fetch("APP_REPOSITORY_URL", "https://github.com/YOUR_ORG/labfire")
  config.x.brand.support_email = ENV.fetch("SUPPORT_EMAIL", "support@example.com")
  config.x.brand.description = ENV.fetch("APP_DESCRIPTION", "Labfire is a focused team chat application.")
end

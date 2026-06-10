require "web_push/vapid_key_file"

Rails.application.configure do
  config.x.vapid.private_key = ENV.fetch("VAPID_PRIVATE_KEY", Rails.application.credentials.dig(:vapid, :private_key))
  config.x.vapid.public_key = ENV.fetch("VAPID_PUBLIC_KEY", Rails.application.credentials.dig(:vapid, :public_key))
  config.x.vapid.subject = ENV.fetch("VAPID_SUBJECT", "mailto:#{config.x.brand.support_email}")

  # Without a configured key pair, generate one and persist it in storage/ so
  # push notifications work out of the box.
  if config.x.vapid.private_key.blank? || config.x.vapid.public_key.blank?
    key = WebPush::VapidKeyFile.load_or_generate(Rails.root.join("storage/vapid.key"))

    config.x.vapid.public_key = key["public_key"]
    config.x.vapid.private_key = key["private_key"]
  end
end

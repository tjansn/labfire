require "web-push"

# Loads the VAPID key pair from a file, generating and persisting one the
# first time. Lets web push notifications work out of the box when no key is
# configured via ENV or credentials. The file lives in storage/ so the key
# pair survives restarts and redeploys; losing it would invalidate every
# existing push subscription.
module WebPush
  class VapidKeyFile
    def self.load_or_generate(path)
      FileUtils.mkdir_p(File.dirname(path))

      File.open(path, File::RDWR | File::CREAT, 0600) do |file|
        file.flock(File::LOCK_EX)

        read(file) || generate(file)
      end
    end

    def self.read(file)
      pair = JSON.parse(file.read) rescue nil
      pair if pair.is_a?(Hash) && pair["public_key"].present? && pair["private_key"].present?
    end

    def self.generate(file)
      key = WebPush.generate_key

      { "public_key" => key.public_key, "private_key" => key.private_key }.tap do |pair|
        file.rewind
        file.truncate(0)
        file.write(JSON.generate(pair))
      end
    end
  end
end

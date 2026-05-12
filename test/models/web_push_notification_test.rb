require "test_helper"

class WebPushNotificationTest < ActiveSupport::TestCase
  test "uses configured VAPID subject" do
    previous_subject = Rails.configuration.x.vapid.subject
    Rails.configuration.x.vapid.subject = "mailto:test@example.com"

    WebPush.expects(:payload_send).with do |payload|
      payload[:vapid][:subject] == "mailto:test@example.com"
    end

    notification.deliver
  ensure
    Rails.configuration.x.vapid.subject = previous_subject
  end

  private
    def notification
      WebPush::Notification.new \
        title: "Title", body: "Body", path: "/", badge: 1,
        endpoint: "https://push.example.com", p256dh_key: "p256dh", auth_key: "auth"
    end
end

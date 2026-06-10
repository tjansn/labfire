class Message::UnfurlLinkJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(message)
    message.unfurl_link
  end
end

require "test_helper"

class Message::UnfurlingTest < ActiveSupport::TestCase
  setup do
    RestrictedHTTP::PrivateNetworkGuard.stubs(:resolve).returns("93.184.216.34")
  end

  test "creating a message with a repo link enqueues an unfurl job" do
    assert_enqueued_with job: Message::UnfurlLinkJob do
      create_message "Check out https://github.com/rails/rails sometime"
    end
  end

  test "creating a message with a non-previewable link does not enqueue a job" do
    assert_no_enqueued_jobs only: Message::UnfurlLinkJob do
      create_message "Check out https://example.com/page sometime"
    end
  end

  test "creating a message without links does not enqueue a job" do
    assert_no_enqueued_jobs only: Message::UnfurlLinkJob do
      create_message "No links here"
    end
  end

  test "messages already unfurled client-side are not unfurled again" do
    body = %(<div>https://github.com/rails/rails<action-text-attachment content-type="#{ActionText::Attachment::OpengraphEmbed::OPENGRAPH_EMBED_CONTENT_TYPE}" url="https://example.com/image.png" href="https://github.com/rails/rails" filename="rails/rails" caption="Ruby on Rails"></action-text-attachment></div>)

    assert_no_enqueued_jobs only: Message::UnfurlLinkJob do
      create_message body
    end
  end

  test "unfurling a repo link stores a card preview and broadcasts an update" do
    stub_opengraph_page "https://github.com/rails/rails",
      title: "rails/rails", description: "Ruby on Rails", image: "https://example.com/social.png"

    message = create_message "Check out https://github.com/rails/rails sometime"
    message.unfurl_link

    preview = message.reload.link_preview
    assert_equal "card", preview["kind"]
    assert_equal "rails/rails", preview["title"]
    assert_equal "Ruby on Rails", preview["description"]
    assert_equal "https://example.com/social.png", preview["image"]
    assert_equal "https://github.com/rails/rails", preview["url"]
  end

  test "unfurling a GIF page link stores a media preview" do
    stub_opengraph_page "https://giphy.com/gifs/funny-abc123",
      title: "Funny GIF", description: "", image: "https://media1.giphy.com/media/abc/giphy.gif", image_content_type: "image/gif"

    message = create_message "https://giphy.com/gifs/funny-abc123"
    message.unfurl_link

    preview = message.reload.link_preview
    assert_equal "media", preview["kind"]
    assert_equal "https://media1.giphy.com/media/abc/giphy.gif", preview["image"]
  end

  test "unfurling clears the preview when the link is gone" do
    message = create_message "No more links"
    message.update_columns link_preview: { "kind" => "card", "url" => "https://github.com/rails/rails", "title" => "rails/rails" }

    message.unfurl_link

    assert_nil message.reload.link_preview
  end

  test "unfurl failures leave the message untouched" do
    WebMock.stub_request(:get, "https://github.com/rails/rails").to_timeout

    message = create_message "https://github.com/rails/rails"

    assert_nothing_raised { message.unfurl_link }
    assert_nil message.reload.link_preview
  end

  private
    def create_message(body)
      Message.create! room: rooms(:pets), creator: users(:jason), body: body, client_message_id: Random.uuid
    end

    def stub_opengraph_page(url, title:, description:, image:, image_content_type: "image/png")
      body = <<~HTML
        <html>
          <head>
            <meta property="og:url" content="#{url}">
            <meta property="og:title" content="#{title}">
            <meta property="og:description" content="#{description}">
            <meta property="og:image" content="#{image}">
          </head>
        </html>
      HTML

      WebMock.stub_request(:get, url).to_return(status: 200, body: body, headers: { content_type: "text/html" })
      WebMock.stub_request(:head, image).to_return(status: 200, headers: { content_type: image_content_type })
    end
end

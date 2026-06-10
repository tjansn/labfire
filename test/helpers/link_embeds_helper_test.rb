require "test_helper"

class LinkEmbedsHelperTest < ActionView::TestCase
  test "appends a click-to-play embed for YouTube links" do
    html = embed %(<div class="trix-content"><a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">https://www.youtube.com/watch?v=dQw4w9WgXcQ</a></div>)

    assert_match /<figure class="yt-embed" data-controller="youtube-embed" data-youtube-embed-video-id-value="dQw4w9WgXcQ">/, html
    assert_match %r{https://i\.ytimg\.com/vi/dQw4w9WgXcQ/hqdefault\.jpg}, html
  end

  test "recognizes youtu.be and shorts links" do
    assert_match /data-youtube-embed-video-id-value="dQw4w9WgXcQ"/,
      embed(%(<a href="https://youtu.be/dQw4w9WgXcQ">link</a>))
    assert_match /data-youtube-embed-video-id-value="dQw4w9WgXcQ"/,
      embed(%(<a href="https://www.youtube.com/shorts/dQw4w9WgXcQ">link</a>))
  end

  test "appends inline images for direct image links" do
    html = embed %(<a href="https://example.com/funny.gif">https://example.com/funny.gif</a>)

    assert_match /<figure class="inline-image">/, html
    assert_match %r{<img src="https://example\.com/funny\.gif"[^>]*loading="lazy"}, html
    assert_match /data-lightbox-target="image"/, html
  end

  test "appends inline images for GIF media hosts without file extensions" do
    assert_match /<figure class="inline-image">/,
      embed(%(<a href="https://media1.giphy.com/media/abc123/giphy-downsized.webp?cid=x">gif</a>))
  end

  test "ignores regular links" do
    html = %(<div><a href="https://example.com/page">https://example.com/page</a></div>)
    assert_equal html, embed(html)
  end

  test "does not embed the same URL twice" do
    html = embed %(<a href="https://example.com/a.gif">one</a> <a href="https://example.com/a.gif">two</a>)
    assert_equal 1, html.scan("inline-image\"").size
  end

  test "embeds at most #{LinkEmbedsHelper::MAX_LINK_EMBEDS} links" do
    anchors = (1..5).map { |i| %(<a href="https://example.com/#{i}.gif">#{i}</a>) }.join(" ")
    assert_equal LinkEmbedsHelper::MAX_LINK_EMBEDS, embed(anchors).scan("<figure class=\"inline-image\"").size
  end

  test "upgrades opengraph cards for embeddable links into rich embeds" do
    html = embed <<~HTML
      <figure class="attachment attachment--og">
        <div class="og-embed">
          <div class="og-embed__title"><a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">A video</a></div>
        </div>
      </figure>
    HTML

    assert_no_match /attachment--og/, html
    assert_match /data-youtube-embed-video-id-value="dQw4w9WgXcQ"/, html
    assert_equal 1, html.scan("yt-embed\"").size
  end

  private
    def embed(html)
      render_link_embeds(html)
    end
end

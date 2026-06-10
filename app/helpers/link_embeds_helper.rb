module LinkEmbedsHelper
  MAX_LINK_EMBEDS = 3

  INLINE_IMAGE_PATH = /\.(gif|png|jpe?g|webp|avif)\z/i
  GIF_MEDIA_HOSTS = /\A(media\d*\.giphy\.com|i\.giphy\.com|(media|c)\.tenor\.com)\z/i
  YOUTUBE_URL = %r{\Ahttps?://(?:www\.|m\.|music\.)?(?:youtube\.com/(?:watch\?[^#]*\bv=|shorts/|live/|embed/)|youtu\.be/)(?<id>[\w-]{11})}

  def render_link_embeds(html)
    fragment = Nokogiri::HTML4.fragment(html.to_s)
    embeds, embedded_urls = [], []

    upgrade_unfurled_media_cards fragment, embedded_urls

    fragment.css("a[href]").each do |anchor|
      break if embeds.size >= MAX_LINK_EMBEDS

      url = anchor["href"]
      next if url.blank? || embedded_urls.include?(url) || anchor.ancestors("figure").any?

      if (embed = link_embed_tag(url))
        embeds << embed
        embedded_urls << url
      end
    end

    if embeds.any?
      target = fragment.at_css(".trix-content") || fragment
      embeds.each { |embed| target.add_child(embed.to_s) }
    end

    fragment.to_html.html_safe
  end

  private
    # Replaces opengraph cards for directly-embeddable links (YouTube, images)
    # with their richer inline embeds.
    def upgrade_unfurled_media_cards(fragment, embedded_urls)
      fragment.css("figure.attachment--og").each do |figure|
        url = figure.at_css(".og-embed__title a")&.[]("href")

        if url.present? && (embed = link_embed_tag(url))
          figure.replace(embed.to_s)
          embedded_urls << url
        end
      end
    end

    def link_embed_tag(url)
      if (video_id = youtube_video_id(url))
        youtube_embed_tag(video_id)
      elsif inline_image_url?(url)
        inline_image_embed_tag(url)
      end
    end

    def youtube_video_id(url)
      url.match(YOUTUBE_URL) { |match| match[:id] }
    end

    def inline_image_url?(url)
      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) && (uri.path.to_s.match?(INLINE_IMAGE_PATH) || uri.host.to_s.match?(GIF_MEDIA_HOSTS))
    rescue URI::InvalidURIError
      false
    end

    def youtube_embed_tag(video_id)
      tag.figure class: "yt-embed", data: { controller: "youtube-embed", youtube_embed_video_id_value: video_id } do
        tag.img(src: "https://i.ytimg.com/vi/#{video_id}/hqdefault.jpg", class: "yt-embed__thumbnail", alt: "YouTube video preview", loading: "lazy") +
          tag.button(class: "yt-embed__play", data: { action: "youtube-embed#play" }) do
            youtube_play_icon + tag.span("Play YouTube video", class: "for-screen-reader")
          end
      end
    end

    def youtube_play_icon
      tag.svg viewBox: "0 0 24 24", fill: "currentColor", aria: { hidden: true } do
        tag.path d: "M8 5.5v13l11-6.5z"
      end
    end

    def inline_image_embed_tag(url)
      filename = File.basename(URI.parse(url).path.presence || "image")

      tag.figure class: "inline-image" do
        link_to url, class: "inline-image__link flex", target: "_blank", rel: "noreferrer",
          aria: { label: "Open #{filename}" },
          data: { lightbox_target: "image", action: "lightbox#open", lightbox_url_value: url, lightbox_filename_value: filename } do
          tag.img src: url, class: "inline-image__img", alt: filename, loading: "lazy"
        end
      end
    end
end

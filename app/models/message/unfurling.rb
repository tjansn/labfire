module Message::Unfurling
  extend ActiveSupport::Concern

  CARD_PREVIEW_HOSTS = %w[ github.com gist.github.com gitlab.com bitbucket.org codeberg.org ]
  MEDIA_PREVIEW_HOSTS = %w[ giphy.com tenor.com ]

  included do
    after_create_commit :unfurl_link_later
  end

  def unfurl_link_later
    Message::UnfurlLinkJob.perform_later(self) if unfurlable_url.present? || link_preview.present?
  end

  def unfurl_link
    if (url = unfurlable_url)
      refresh_link_preview_from url
    elsif link_preview.present?
      update_link_preview nil
    end
  rescue StandardError => e
    Rails.logger.warn "Link unfurl failed for message #{id}: #{e.class} `#{e.message}`"
  end

  private
    def refresh_link_preview_from(url)
      metadata = Opengraph::Metadata.from_url(url)
      preview = link_preview_attributes(metadata, url)

      update_link_preview preview if preview != link_preview
    end

    def update_link_preview(preview)
      update! link_preview: preview
      broadcast_presentation_update
    end

    def unfurlable_url
      return nil unless content_type.text?
      return nil if client_unfurled?

      extracted_urls.find { |url| previewable_host?(url) }
    end

    def extracted_urls
      plain_text_body.scan(%r{https?://[^\s<>"']+})
    end

    def previewable_host?(url)
      normalized_host(url).in?(CARD_PREVIEW_HOSTS + MEDIA_PREVIEW_HOSTS)
    end

    def media_preview_host?(url)
      normalized_host(url).in?(MEDIA_PREVIEW_HOSTS)
    end

    def normalized_host(url)
      URI.parse(url).host&.downcase&.delete_prefix("www.")
    rescue URI::InvalidURIError
      nil
    end

    def client_unfurled?
      body.body.fragment.find_all("action-text-attachment[content-type='#{ActionText::Attachment::OpengraphEmbed::OPENGRAPH_EMBED_CONTENT_TYPE}']").any?
    end

    def link_preview_attributes(metadata, source_url)
      if media_preview_host?(source_url)
        return nil unless metadata.title.present? && metadata.image.present?

        { "kind" => "media", "url" => source_url, "title" => metadata.title, "image" => metadata.image }
      else
        return nil unless metadata.valid?

        url = Opengraph::Location.new(metadata.url).valid? ? metadata.url : source_url

        { "kind" => "card", "url" => url, "title" => metadata.title,
          "description" => metadata.description, "image" => metadata.image }.compact
      end
    end
end

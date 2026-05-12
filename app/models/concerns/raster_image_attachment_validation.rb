module RasterImageAttachmentValidation
  extend ActiveSupport::Concern

  ALLOWED_CONTENT_TYPES = %w[ image/png image/jpeg image/webp ].freeze
  MAX_BYTE_SIZE = 5.megabytes

  class_methods do
    def validates_raster_image_attachment(name, max_byte_size: MAX_BYTE_SIZE)
      validate do
        attachment = public_send(name)
        next unless attachment.attached?

        blob = attachment.blob

        unless blob.content_type.in?(ALLOWED_CONTENT_TYPES)
          errors.add name, "must be a PNG, JPEG, or WebP image"
        end

        if blob.byte_size > max_byte_size
          errors.add name, "must be 5 MB or smaller"
        end

        unless blob.variable?
          errors.add name, "must be a processable raster image"
        end
      end
    end
  end
end

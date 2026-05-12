module User::Avatar
  extend ActiveSupport::Concern
  include RasterImageAttachmentValidation

  included do
    has_one_attached :avatar
    validates_raster_image_attachment :avatar
  end

  class_methods do
    def from_avatar_token(sid)
      find_signed!(sid, purpose: :avatar)
    end
  end

  def avatar_token
    signed_id(purpose: :avatar)
  end
end

class Account < ApplicationRecord
  include Joinable, RasterImageAttachmentValidation

  has_one_attached :logo
  validates_raster_image_attachment :logo
  has_json :settings, restrict_room_creation_to_administrators: false
end

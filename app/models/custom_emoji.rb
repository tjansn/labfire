class CustomEmoji < ApplicationRecord
  include RasterImageAttachmentValidation

  SHORTCODE_FORMAT = /\A:[a-z0-9_+-]+:\z/

  belongs_to :creator, class_name: "User", default: -> { Current.user }
  has_one_attached :image

  validates :name, presence: true, length: { maximum: 32 }, uniqueness: { case_sensitive: false },
    format: { with: /\A[a-z0-9_+-]+\z/, message: "can only contain lowercase letters, numbers, underscores, plus signs, and hyphens" }
  validates_raster_image_attachment :image, max_byte_size: 1.megabyte
  validate :image_attached

  before_validation :normalize_name

  scope :ordered, -> { order(:name) }

  def self.find_by_shortcode(shortcode)
    return unless shortcode.to_s.match?(SHORTCODE_FORMAT)

    find_by(name: shortcode.to_s.delete_prefix(":").delete_suffix(":"))
  end

  def shortcode
    ":#{name}:"
  end

  def title
    name.tr("_-", "  ").squish.titleize
  end

  private
    def normalize_name
      self.name = name.to_s.strip.downcase.gsub(/\A:+|:+\z/, "").parameterize(separator: "_")
    end

    def image_attached
      errors.add :image, "must be attached" unless image.attached?
    end
end

class Boost < ApplicationRecord
  belongs_to :message, touch: true
  belongs_to :booster, class_name: "User", default: -> { Current.user }

  validates :content, presence: true, length: { maximum: 16 }, uniqueness: { scope: %i[ message_id booster_id ] }

  scope :ordered, -> { order(:created_at, :id) }
end

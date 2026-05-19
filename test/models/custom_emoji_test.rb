require "test_helper"

class CustomEmojiTest < ActiveSupport::TestCase
  test "normalizes a name into a shortcode" do
    emoji = CustomEmoji.new name: ":Party Parrot:", creator: users(:david), image: uploaded_image

    assert emoji.valid?
    assert_equal "party_parrot", emoji.name
    assert_equal ":party_parrot:", emoji.shortcode
  end

  test "requires an image" do
    emoji = CustomEmoji.new name: "party", creator: users(:david)

    assert_not emoji.valid?
    assert_includes emoji.errors[:image], "must be attached"
  end

  test "finds an emoji by shortcode" do
    emoji = CustomEmoji.create! name: "party", creator: users(:david), image: uploaded_image

    assert_equal emoji, CustomEmoji.find_by_shortcode(":party:")
    assert_nil CustomEmoji.find_by_shortcode("party")
  end

  private
    def uploaded_image
      Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/moon.jpg"), "image/jpeg")
    end
end

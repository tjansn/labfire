require "test_helper"

class CustomEmojisControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "create uploads a custom emoji" do
    assert_difference -> { CustomEmoji.count }, 1 do
      post custom_emojis_url, params: {
        custom_emoji: {
          name: "Party Parrot",
          image: fixture_file_upload("moon.jpg", "image/jpeg")
        }
      }, headers: { "HTTP_REFERER" => root_url }
    end

    assert_redirected_to root_url
    assert_equal ":party_parrot:", CustomEmoji.last.shortcode
  end

  test "create redirects back with an alert when invalid" do
    assert_no_difference -> { CustomEmoji.count } do
      post custom_emojis_url, params: { custom_emoji: { name: "party" } }, headers: { "HTTP_REFERER" => root_url }
    end

    assert_redirected_to root_url
    assert_equal "Image must be attached", flash[:alert]
  end
end

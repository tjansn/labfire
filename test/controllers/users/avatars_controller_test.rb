require "test_helper"

class Users::AvatarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "show initials" do
    get user_avatar_url(users(:kevin).avatar_token)

    assert_response :success
    assert_select "text", text: "K"
  end

  test "show default bot image" do
    get user_avatar_url(users(:bender).avatar_token)

    assert_response :success
    assert_equal "image/svg+xml", @response.content_type
  end

  test "show image" do
    users(:kevin).update! avatar: fixture_file_upload("moon.jpg", "image/jpeg")
    get user_avatar_url(users(:kevin).avatar_token)

    assert_response :success
    assert_equal "image/webp", @response.content_type
  end

  test "show legacy non-variable avatar falls back to initials" do
    attach_legacy_avatar users(:kevin), content: "not an image", filename: "avatar.txt", content_type: "text/plain"

    get user_avatar_url(users(:kevin).avatar_token)

    assert_response :success
    assert_equal "image/svg+xml", @response.media_type
    assert_select "text", text: "K"
  end

  test "show image with invalid token responds 404" do
    get user_avatar_url("not-a-valid-token")

    assert_response :not_found
  end

  private
    def attach_legacy_avatar(user, content:, filename:, content_type:)
      blob = ActiveStorage::Blob.create_and_upload! \
        io: StringIO.new(content), filename: filename, content_type: content_type

      ActiveStorage::Attachment.create! name: "avatar", record: user, blob: blob
    end
end

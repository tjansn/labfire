require "test_helper"
require "vips"

class Accounts::LogosControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "show stock" do
    get account_logo_url
    assert_valid_png_response size: 512
  end

  test "show stock small size" do
    get account_logo_url(size: :small)
    assert_valid_png_response size: 192
  end

  test "show favicon" do
    get "/favicon.ico"
    assert_valid_png_response size: 192
  end

  test "show custom" do
    accounts(:signal).update! logo: fixture_file_upload("moon.jpg", "image/jpeg")

    get account_logo_url
    assert_valid_png_response size: 512
  end

  test "show custom small size" do
    accounts(:signal).update! logo: fixture_file_upload("moon.jpg", "image/jpeg")

    get account_logo_url(size: :small)
    assert_valid_png_response size: 192
  end

  test "show legacy non-variable logo falls back to stock" do
    attach_legacy_logo content: "<!doctype html><h1>not an image</h1>", filename: "logo.html", content_type: "text/html"

    get account_logo_url
    assert_valid_png_response size: 512
  end

  test "destroy" do
    accounts(:signal).update! logo: fixture_file_upload("moon.jpg", "image/jpeg")

    delete account_logo_url
    assert_redirected_to edit_account_url
    assert_not accounts(:signal).reload.logo.attached?
  end

  private
    def attach_legacy_logo(content:, filename:, content_type:)
      blob = ActiveStorage::Blob.create_and_upload! \
        io: StringIO.new(content), filename: filename, content_type: content_type

      ActiveStorage::Attachment.create! name: "logo", record: accounts(:signal), blob: blob
    end

    def assert_valid_png_response(size:)
      assert_equal @response.headers["content-type"], "image/png"

      image = ::Vips::Image.new_from_buffer(@response.body, "")
      assert_equal size, image.width
      assert_equal size, image.height
    end
end

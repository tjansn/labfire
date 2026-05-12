require "test_helper"

class AccountTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess

  test "settings" do
    accounts(:signal).settings.restrict_room_creation_to_administrators = true
    assert accounts(:signal).settings.restrict_room_creation_to_administrators?
    assert_equal({ "restrict_room_creation_to_administrators" => true }, accounts(:signal)[:settings])

    accounts(:signal).update!(settings: { "restrict_room_creation_to_administrators" => "true" })
    assert accounts(:signal).reload.settings.restrict_room_creation_to_administrators?

    accounts(:signal).settings.restrict_room_creation_to_administrators = false
    assert_not accounts(:signal).settings.restrict_room_creation_to_administrators?
    assert_equal({ "restrict_room_creation_to_administrators" => false }, accounts(:signal)[:settings])
    accounts(:signal).update!(settings: { "restrict_room_creation_to_administrators" => "false" })
    assert_not accounts(:signal).reload.settings.restrict_room_creation_to_administrators?
  end

  test "logo accepts raster images" do
    account = Account.new name: "Test", logo: fixture_file_upload("moon.jpg", "image/jpeg")

    assert account.valid?
  end

  test "logo rejects svg and html uploads" do
    [ [ "unsafe.svg", "image/svg+xml" ], [ "unsafe.html", "text/html" ] ].each do |filename, content_type|
      account = Account.new name: "Test", logo: fixture_file_upload(filename, content_type)

      assert_not account.valid?, "#{filename} should be rejected"
      assert_includes account.errors[:logo], "must be a PNG, JPEG, or WebP image"
    end
  end
end

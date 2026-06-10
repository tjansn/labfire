require "test_helper"
require "web_push/vapid_key_file"

class WebPush::VapidKeyFileTest < ActiveSupport::TestCase
  setup do
    @path = Rails.root.join("tmp", "vapid_key_file_test_#{Process.pid}_#{SecureRandom.hex(4)}.key")
  end

  teardown do
    File.delete(@path) if File.exist?(@path)
  end

  test "generates and persists a key pair when the file is missing" do
    pair = WebPush::VapidKeyFile.load_or_generate(@path)

    assert pair["public_key"].present?
    assert pair["private_key"].present?
    assert_equal pair, JSON.parse(File.read(@path))
  end

  test "returns the persisted key pair on subsequent loads" do
    first = WebPush::VapidKeyFile.load_or_generate(@path)
    second = WebPush::VapidKeyFile.load_or_generate(@path)

    assert_equal first, second
  end

  test "regenerates when the file is corrupt" do
    File.write(@path, "not json")

    pair = WebPush::VapidKeyFile.load_or_generate(@path)

    assert pair["public_key"].present?
    assert_equal pair, JSON.parse(File.read(@path))
  end

  test "generated keys are usable for VAPID signing" do
    pair = WebPush::VapidKeyFile.load_or_generate(@path)

    assert_nothing_raised do
      WebPush::VapidKey.from_keys(pair["public_key"], pair["private_key"]).curve
    end
  end
end

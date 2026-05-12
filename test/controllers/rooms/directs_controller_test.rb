require "test_helper"

class Rooms::DirectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "new" do
    get new_rooms_direct_url
    assert_response :success
    assert_select ".gl-direct-new-card form[action='#{rooms_directs_path}']"
  end

  test "new in sidebar frame" do
    get new_rooms_direct_url, headers: { "Turbo-Frame" => "direct_rooms_control" }
    assert_response :success
    assert_select "turbo-frame#direct_rooms_control form[action='#{rooms_directs_path}']"
  end

  test "create" do
    post rooms_directs_url, params: { user_ids: [ users(:jz).id ] }

    room = Room.last
    assert_redirected_to room_url(room)
    assert room.users.include?(users(:david))
    assert room.users.include?(users(:jz))
  end

  test "create only once per user set" do
    assert_difference -> { Room.all.count }, +1 do
      post rooms_directs_url, params: { user_ids: [ users(:jz).id ] }
      post rooms_directs_url, params: { user_ids: [ users(:jz).id ] }
    end
  end

  test "destroy only allowed for all room users" do
    sign_in :kevin

    assert_difference -> { Room.count }, -1 do
      delete rooms_direct_url(rooms(:david_and_kevin))
      assert_redirected_to root_url
    end
  end
end

require "test_helper"

class Messages::BoostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
    @message = messages(:first)
  end

  test "create" do
    assert_turbo_stream_broadcasts [ @message.room, :messages ], count: 1 do
      assert_difference -> { @message.boosts.count }, 1 do
        post message_boosts_url(@message, format: :turbo_stream), params: { boost: { content: "Morning!" } }
        assert_redirected_to message_boosts_url(@message)
      end
    end
  end

  test "destroy" do
    assert_turbo_stream_broadcasts [ @message.room, :messages ], count: 1 do
      assert_difference -> { @message.boosts.count }, -1 do
        delete message_boost_url(@message, boosts(:first), format: :turbo_stream)
        assert_response :success
      end
    end
  end

  test "boost delete accessible descriptions use unique ids" do
    boost = @message.boosts.create! booster: users(:jason), content: "Again"

    get room_message_url(@message.room, @message)

    assert_select "#delete_boost_accessible_label", count: 0
    [ boosts(:first), boost ].each do |message_boost|
      label_id = dom_id(message_boost, :delete_accessible_label)
      assert_select "##{label_id}", count: 1
      assert_select "[aria-describedby='#{label_id}']", count: 1
    end
  end
end

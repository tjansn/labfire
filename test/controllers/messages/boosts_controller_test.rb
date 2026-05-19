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

  test "create does not duplicate the same reaction by the same user" do
    assert_no_turbo_stream_broadcasts [ @message.room, :messages ] do
      assert_no_difference -> { @message.boosts.count } do
        post message_boosts_url(@message, format: :turbo_stream), params: { boost: { content: boosts(:first).content } }
        assert_redirected_to message_boosts_url(@message)
      end
    end
  end

  test "destroy" do
    assert_turbo_stream_broadcasts [ @message.room, :messages ], count: 1 do
      assert_difference -> { @message.boosts.count }, -1 do
        delete message_boost_url(@message, boosts(:first), format: :turbo_stream)
        assert_redirected_to message_boosts_url(@message)
      end
    end
  end

  test "index stacks reactions shared by the same boosters" do
    @message.boosts.create! booster: users(:jason), content: "Hello"
    @message.boosts.create! booster: users(:david), content: "👋"
    @message.boosts.create! booster: users(:jason), content: "👋"

    get message_boosts_url(@message)

    assert_select ".boost-stack", count: 1
    assert_select ".boost-stack__avatar", count: 2
    assert_select ".boost__content", text: "Hello", count: 1
    assert_select ".boost__content", text: "👋", count: 1
  end

  test "index shows a reactor overflow summary when more than three users reacted" do
    @message.boosts.destroy_all
    [ users(:david), users(:jason), users(:jz), users(:kevin) ].each do |user|
      @message.boosts.create! booster: user, content: "🔥"
    end

    get message_boosts_url(@message)

    assert_select ".boost-stack__avatar", count: 3
    assert_select ".boost-stack__more", text: "+1", count: 1
    assert_select ".boost-stack__reactor", count: 4
  end

  test "boost delete accessible descriptions use unique ids" do
    @message.boosts.create! booster: users(:jason), content: "Again"

    get room_message_url(@message.room, @message)

    assert_select "#delete_boost_accessible_label", count: 0
    assert_select "span[id$='_delete_accessible_label']", count: 2
  end
end

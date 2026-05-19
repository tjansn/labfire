require "test_helper"

class BoostTest < ActiveSupport::TestCase
  test "same user can only add the same reaction to a message once" do
    duplicate = messages(:first).boosts.build booster: users(:david), content: boosts(:first).content

    assert_not duplicate.valid?
  end

  test "stacks reactions by matching booster sets" do
    message = messages(:third)

    message.boosts.create! booster: users(:david), content: "🔥"
    message.boosts.create! booster: users(:jason), content: "🔥"
    message.boosts.create! booster: users(:david), content: "✅"

    assert_equal [
      [ [ users(:david).id, users(:jason).id ], [ "🔥" ] ],
      [ [ users(:david).id ], [ "✅" ] ]
    ], stack_signature(Boost::Stack.build(message.boosts.ordered.to_a))
  end

  test "combines multiple reactions shared by the same users into one stack" do
    message = messages(:third)

    message.boosts.create! booster: users(:david), content: "🔥"
    message.boosts.create! booster: users(:jason), content: "🔥"
    message.boosts.create! booster: users(:david), content: "✅"
    message.boosts.create! booster: users(:jason), content: "✅"

    assert_equal [
      [ [ users(:david).id, users(:jason).id ], [ "🔥", "✅" ] ]
    ], stack_signature(Boost::Stack.build(message.boosts.ordered.to_a))
  end

  private
    def stack_signature(stacks)
      stacks.map { |stack| [ stack.boosters.map(&:id), stack.contents ] }
    end
end

require "application_system_test_case"

class BoostingMessagesTest < ApplicationSystemTestCase
  setup do
    sign_in "kevin@37signals.com"
    join_room rooms(:designers)
  end

  test "boosting a message" do
    within_message messages(:third) do
      reveal_message_actions
      fill_in_boost_input "Good morning"
      click_on "Submit"
      assert_boost_text "Good morning"
    end
  end

  test "adding a reaction by clicking an existing reaction" do
    within_message messages(:first) do
      find("button.boost__content", text: "Hello").click

      assert_selector ".boost-stack__avatar", count: 2
      assert_boost_text "Hello"
    end
  end

  test "uploading and choosing a custom emoji" do
    within_message messages(:third) do
      reveal_message_actions
      find(".message__reaction-picker summary[aria-label='Emoji menu']").click

      find(".message__custom-emoji-name").fill_in with: "moon"
      custom_emoji_file_input = find("##{dom_id(messages(:third))}_custom_emoji_image", visible: :all)
      page.execute_script("arguments[0].style.opacity = 1; arguments[0].style.position = 'static'", custom_emoji_file_input)
      custom_emoji_file_input.set Rails.root.join("test/fixtures/files/moon.jpg")
      click_on "Upload custom emoji"
    end

    within_message messages(:third) do
      reveal_message_actions
      find(".message__reaction-picker summary[aria-label='Emoji menu']").click
      click_on "React with Moon"

      assert_selector ".boost .custom-emoji"
    end
  end

  test "thread panel messages show the same hover actions as the main stream" do
    within_message messages(:third) do
      reveal_message_actions
      click_on "Reply in thread"
    end

    assert_selector ".thread-panel"

    within ".thread-panel .thread-panel__parent" do
      find(".message__actions", visible: :all).hover

      assert_selector ".message__hover-actions > form", count: EmojiHelper::QUICK_REACTION_LIMIT, visible: true
      assert_selector ".message__reaction-picker summary[aria-label='Emoji menu']", visible: true
      assert_selector ".message__boost-btn", visible: true

      find(".message__reaction-picker summary[aria-label='Emoji menu']").click
      within ".message__reaction-menu" do
        assert_selector "button[title='Fire']", visible: true
        assert_selector ".message__reaction-field", visible: true
      end
    end
  end

  test "deleting a boost" do
    using_session("David") do
      sign_in "david@37signals.com"
      join_room rooms(:designers)

      within_message messages(:first) do
        find("button.boost__content", text: "Hello").click
        assert_selector "button", text: "Delete this boost", wait: 5
        click_on "Delete this boost"
      end

      assert_no_selector ".boost__content", text: "Hello"
    end
  end

  test "message update preserves the input state" do
    within_message messages(:third) do
      assert_message_text "Third time's a charm."
      reveal_message_actions
      fill_in_boost_input "Hey!"
    end

    using_session("JZ") do
      sign_in "jz@37signals.com"
      join_room rooms(:designers)

      within_message messages(:third) do
        reveal_message_actions
        find(".message__edit-btn").click

        fill_in_rich_text_area "message_body", with: "Redacted!"
        click_on "Save changes"
      end
    end

    within_message messages(:third) do
      assert_message_text "Redacted!"
      assert_boost_input_value "Hey!"
    end
  end

  test "boost by another user preserves the input state" do
    within_message messages(:third) do
      assert_message_text "Third time's a charm."
      reveal_message_actions
      fill_in_boost_input "Hey!"
    end

    using_session("David") do
      sign_in "david@37signals.com"
      join_room rooms(:designers)

      within_message messages(:third) do
        reveal_message_actions
        fill_in_boost_input "Morning"
        click_on "Submit"
        assert_boost_text "Morning"
      end
    end

    perform_enqueued_jobs

    within_message messages(:third) do
      assert_boost_text "Morning"
      assert_boost_input_value "Hey!"
    end
  end

  private
    def fill_in_boost_input(text)
      click_on "New boost"
      fill_in "boost[content]", with: text
    end

    def assert_boost_input_value(text)
      assert page.has_field? "boost[content]", with: text
    end

    def assert_boost_text(text, **options)
      assert_selector ".boost", text: text, **options
    end
end

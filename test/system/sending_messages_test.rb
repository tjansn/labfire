require "application_system_test_case"

class SendingMessagesTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
    join_room rooms(:designers)
  end

  test "sending messages between two users" do
    using_session("Kevin") do
      sign_in "kevin@37signals.com"
      join_room rooms(:designers)
    end

    join_room rooms(:designers)
    send_message "Is this thing on?"

    using_session("Kevin") do
      join_room rooms(:designers)
      assert_message_text "Is this thing on?"

      send_message "👍👍"
    end

    join_room rooms(:designers)
    assert_message_text "👍👍"
  end

  test "inserting an emoji from the composer emoji menu" do
    find(".composer__emoji-picker summary[aria-label='Emoji menu']").click
    assert page.evaluate_script(<<~JS)
      (() => {
        const rect = document.querySelector('.composer__emoji-menu').getBoundingClientRect()
        return rect.top >= 0 && rect.left >= 0 && rect.bottom <= window.innerHeight && rect.right <= window.innerWidth
      })()
    JS

    within ".composer__emoji-menu" do
      find("button[title='Fire']").click
    end
    click_on "Send message"

    assert_message_text "🔥"
  end

  test "composer and reaction emoji menus share the same visual layout" do
    find(".composer__emoji-picker summary[aria-label='Emoji menu']").click
    composer_metrics = emoji_menu_visual_metrics(".composer__emoji-picker[open] .composer__emoji-menu")
    find(".composer__emoji-picker summary[aria-label='Emoji menu']").click

    within_message messages(:third) do
      reveal_message_actions
      find(".message__reaction-picker summary[aria-label='Emoji menu']", visible: :all).click
    end

    assert_equal composer_metrics, emoji_menu_visual_metrics(".message__reaction-picker[open] .message__reaction-menu")
  end

  test "inserting a custom emoji from the composer emoji menu" do
    CustomEmoji.create! name: "moon", creator: users(:david), image: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/moon.jpg"), "image/jpeg")

    visit current_url
    wait_for_cable_connection

    find(".composer__emoji-picker summary[aria-label='Emoji menu']").click
    within ".composer__emoji-menu" do
      click_on "Insert Moon"
    end
    click_on "Send message"

    assert_selector ".message__body .custom-emoji--message"
    assert_no_selector ".message__body", text: ":moon:"
  end

  test "uploading a custom emoji from the composer emoji menu" do
    find(".composer__emoji-picker summary[aria-label='Emoji menu']").click
    within ".composer__emoji-menu" do
      find(".message__custom-emoji-name").fill_in with: "composer_moon"
      custom_emoji_file_input = find("#composer_custom_emoji_image", visible: :all)
      page.execute_script("arguments[0].style.opacity = 1; arguments[0].style.position = 'static'", custom_emoji_file_input)
      custom_emoji_file_input.set Rails.root.join("test/fixtures/files/moon.jpg")
      click_on "Upload custom emoji"
    end

    assert_selector "summary[aria-label='Emoji menu']"
    visit current_url
    wait_for_cable_connection

    find(".composer__emoji-picker summary[aria-label='Emoji menu']").click
    within ".composer__emoji-menu" do
      click_on "Insert Composer Moon"
    end
    click_on "Send message"

    assert_selector ".message__body .custom-emoji--message"
  end

  test "editing messages" do
    using_session("Kevin") do
      sign_in "kevin@37signals.com"
      join_room rooms(:designers)
    end

    within_message messages(:third) do
      reveal_message_actions
      find(".message__edit-btn").click
      fill_in_rich_text_area "message_body", with: "Redacted!"
      click_on "Save changes"
    end

    using_session("Kevin") do
      join_room rooms(:designers)

      assert_message_text "Redacted!"
    end
  end

  test "deleting messages" do
    using_session("Kevin") do
      sign_in "kevin@37signals.com"
      join_room rooms(:designers)

      assert_message_text "Third time's a charm."
    end

    within_message messages(:third) do
      reveal_message_actions
      find(".message__edit-btn").click

      accept_confirm do
        click_on "Delete message"
      end
    end

    using_session("Kevin") do
      assert_message_text "Third time's a charm.", count: 0
    end
  end

  private
    def emoji_menu_visual_metrics(selector)
      page.evaluate_script(<<~JS)
        (() => {
          const menu = document.querySelector(#{selector.to_json})
          const grid = menu.querySelector('.message__reaction-grid')
          const button = menu.querySelector('.message__reaction-menu-btn')
          const field = menu.querySelector('.message__reaction-field')
          const input = menu.querySelector('.message__reaction-input')
          const upload = menu.querySelector('.message__custom-emoji-form')
          const submit = upload.querySelector('.message__custom-emoji-submit')
          const size = (element) => {
            const rect = element.getBoundingClientRect()
            return { width: Math.round(rect.width), height: Math.round(rect.height) }
          }
          const styles = (element) => {
            const style = getComputedStyle(element)
            return {
              display: style.display,
              padding: style.padding,
              marginInlineEnd: style.marginInlineEnd,
              gridTemplateColumns: style.gridTemplateColumns,
              lineHeight: style.lineHeight
            }
          }

          return {
            menu: { ...size(menu), lineHeight: getComputedStyle(menu).lineHeight },
            grid: { ...size(grid), gridTemplateColumns: getComputedStyle(grid).gridTemplateColumns },
            button: { ...size(button), ...styles(button) },
            field: { ...size(field), ...styles(field) },
            input: { ...size(input), ...styles(input) },
            upload: { ...size(upload), gridTemplateColumns: getComputedStyle(upload).gridTemplateColumns },
            submit: { ...size(submit), ...styles(submit) }
          }
        })()
      JS
    end
end

require "test_helper"

class IconsHelperTest < ActionView::TestCase
  test "decorative icon is hidden from assistive technology" do
    rendered = icon "check"

    assert_match(/aria-hidden="true"/, rendered)
    assert_no_match(/role="img"/, rendered)
  end

  test "labelled icon exposes an image role and accessible label" do
    rendered = icon "notification-bell-alert", decorative: false, label: "Notifications"

    assert_match(/role="img"/, rendered)
    assert_match(/aria-label="Notifications"/, rendered)
    assert_no_match(/aria-hidden="true"/, rendered)
  end

  test "uicon keeps compatibility with alt labels" do
    rendered = uicon "lock", alt: "Secure"

    assert_match(/role="img"/, rendered)
    assert_match(/aria-label="Secure"/, rendered)
    assert_no_match(/alt=/, rendered)
  end
end

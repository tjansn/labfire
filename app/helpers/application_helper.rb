module ApplicationHelper
  def page_title_tag
    tag.title @page_title || "Labfire"
  end

  def current_user_meta_tags
    unless Current.user.nil?
      safe_join [
        tag(:meta, name: "current-user-id", content: Current.user.id),
        tag(:meta, name: "current-user-name", content: Current.user.name)
      ]
    end
  end

  def custom_styles_tag
    if custom_styles = Current.account&.custom_styles
      tag.style(custom_styles.to_s.html_safe, data: { turbo_track: "reload" })
    end
  end

  def body_classes
    [ @body_class, admin_body_class, account_logo_body_class ].compact.join(" ")
  end

  def link_back
    back_url = request.referrer
    back_url = root_path if back_url.nil? || back_url == request.url
    link_back_to back_url
  end

  def link_back_to(destination)
    link_to destination, class: "btn" do
      uicon("arrow-left") + tag.span("Go Back", class: "for-screen-reader")
    end
  end

  UICON_MAP = {
    "add" => "plus",
    "alert" => "triangle-warning",
    "arrow-down" => "arrow-down",
    "arrow-left" => "arrow-left",
    "arrow-right" => "arrow-right",
    "arrow-up" => "arrow-up",
    "art" => "palette",
    "attachment" => "paperclip-vertical",
    "bio" => "user-pen",
    "boost" => "flame",
    "bot" => "robot",
    "broom" => "broom",
    "camera" => "camera",
    "cancel" => "cross-small",
    "check" => "check",
    "common-file-text" => "document",
    "copy-paste" => "copy",
    "crown" => "crown",
    "disclosure" => "angle-small-right",
    "download" => "download",
    "email" => "envelope",
    "everyone" => "users-alt",
    "help" => "interrogation",
    "help-circle" => "info",
    "key" => "key",
    "lanyard" => "id-badge",
    "laptop" => "laptop",
    "lifebuoy" => "life-ring",
    "link" => "link",
    "lock" => "lock",
    "login-keys" => "key",
    "logout" => "sign-out-alt",
    "menu" => "menu-burger",
    "menu-dots-horizontal" => "menu-dots",
    "menu-dots-vertical" => "menu-dots-vertical",
    "messages" => "comment",
    "messages-add" => "comment-pen",
    "messages-empty" => "comment-dots",
    "messages-outlined" => "comment",
    "minus" => "minus-small",
    "mobile-phone" => "mobile-button",
    "notification-bell-alert" => "bell-ring",
    "notification-bell-everything" => "bell",
    "notification-bell-invisible" => "eye-crossed",
    "notification-bell-loading" => "bell",
    "notification-bell-mentions" => "at",
    "notification-bell-nothing" => "bell-slash",
    "office" => "building",
    "password" => "key",
    "pencil" => "pencil",
    "person" => "user",
    "person-add" => "user-add",
    "qr-code" => "qrcode",
    "refresh" => "refresh",
    "remove" => "cross-small",
    "remove-circle" => "cross-circle",
    "reply" => "undo-alt",
    "search" => "search",
    "settings" => "settings-sliders",
    "share" => "share",
    "text-options" => "text",
    "transfer" => "arrows-repeat",
    "trash" => "trash",
    "web" => "globe"
  }.freeze

  def uicon(name, size: 20, **opts)
    glyph = UICON_MAP.fetch(name.to_s) { name.to_s }
    classes = [ "fi", "fi-rr-#{glyph}", opts.delete(:class) ].compact.join(" ")
    style = [ "font-size: #{size}px", opts.delete(:style) ].compact.join("; ")
    tag.i(class: classes, style: style, aria: { hidden: "true" }, **opts)
  end

  private
    def admin_body_class
      "admin" if Current.user&.can_administer?
    end

    def account_logo_body_class
      "account-has-logo" if Current.account&.logo&.attached?
    end
end

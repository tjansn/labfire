module IconsHelper
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
    "emoji" => "palette",
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
    "send" => "envelope",
    "settings" => "settings-sliders",
    "share" => "share",
    "text-options" => "text",
    "transfer" => "arrows-repeat",
    "trash" => "trash",
    "web" => "globe"
  }.freeze

  def icon(name, size: 20, decorative: true, label: nil, **options)
    label ||= options.delete(:alt)
    decorative = false if label.present?

    glyph = UICON_MAP.fetch(name.to_s) { name.to_s }
    classes = [ "fi", "fi-rr-#{glyph}", options.delete(:class) ].compact.join(" ")
    style = [ "font-size: #{size}px", options.delete(:style) ].compact.join("; ")
    aria = icon_aria_options(options.delete(:aria), decorative:, label:)

    tag.i(class: classes, style: style, aria: aria, **icon_role_options(options, decorative:))
  end

  def uicon(name, size: 20, **options)
    label = options.delete(:alt)
    aria = options[:aria]

    if aria.is_a?(Hash)
      aria = aria.dup
      label ||= aria.delete(:label) || aria.delete("label")
      aria.delete(:hidden)
      aria.delete("hidden")
      options[:aria] = aria
    end

    icon name, size: size, decorative: label.blank?, label: label, **options
  end

  private
    def icon_aria_options(aria, decorative:, label:)
      aria = (aria || {}).to_h.symbolize_keys

      if decorative
        aria[:hidden] = "true"
      else
        aria.delete(:hidden)
        aria[:label] = label if label.present?
      end

      aria
    end

    def icon_role_options(options, decorative:)
      decorative ? options : options.reverse_merge(role: "img")
    end
end

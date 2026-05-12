require "zlib"

module Users::AvatarsHelper
  AVATAR_COLORS = %w[
    #050505 #131616 #6C655C #C12A0B
  ]
  AVATAR_TEXT_COLOR = "#F5F3F0"

  def avatar_background_color(user)
    AVATAR_COLORS[Zlib.crc32(user.to_param) % AVATAR_COLORS.size]
  end

  def avatar_text_color
    AVATAR_TEXT_COLOR
  end

  def avatar_tag(user, **options)
    link_to user_path(user), title: user.title, class: "btn avatar",
            aria: { label: "View #{user.name}'s profile" },
            data: { turbo_frame: "_top" } do
      image_tag fresh_user_avatar_path(user), alt: "", aria: { hidden: "true" }, size: 48, **options
    end
  end
end

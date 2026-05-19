module EmojiHelper
  REACTIONS = {
    "👍" => "Thumbs up",
    "👏" => "Clapping",
    "👋" => "Waving hand",
    "💪" => "Muscle",
    "❤️" => "Red heart",
    "😂" => "Face with tears of joy",
    "🎉" => "Party popper",
    "🔥" => "Fire",
    "😍" => "Heart eyes",
    "🙏" => "Folded hands",
    "🙌" => "Raised hands",
    "🤝" => "Handshake",
    "👌" => "OK hand",
    "👀" => "Eyes",
    "🤔" => "Thinking face",
    "😅" => "Grinning face with sweat",
    "😭" => "Loudly crying face",
    "😎" => "Smiling face with sunglasses",
    "😮" => "Surprised face",
    "😢" => "Crying face",
    "😡" => "Angry face",
    "🤯" => "Exploding head",
    "🥳" => "Partying face",
    "😴" => "Sleeping face",
    "🤘" => "Rock on",
    "💯" => "Hundred points",
    "✨" => "Sparkles",
    "🚀" => "Rocket",
    "✅" => "Check mark",
    "❌" => "Cross mark",
    "⚠️" => "Warning",
    "⭐" => "Star",
    "🌈" => "Rainbow",
    "☕" => "Coffee",
    "🍕" => "Pizza",
    "🍰" => "Cake",
    "🐛" => "Bug",
    "💡" => "Light bulb",
    "📌" => "Pushpin",
    "🔒" => "Lock",
    "🫡" => "Saluting face",
    "🫶" => "Heart hands",
    "🤌" => "Pinched fingers",
    "🤷" => "Shrug",
    "🙈" => "See no evil monkey",
    "🐙" => "Octopus",
    "🧪" => "Test tube",
    "🛠️" => "Tools",
    "📣" => "Megaphone",
    "🧯" => "Fire extinguisher"
  }.freeze

  QUICK_REACTION_LIMIT = 4

  def quick_reaction_options(limit: QUICK_REACTION_LIMIT)
    quick_reaction_options_by_limit[limit] ||= begin
      popular_contents = Boost.popular_contents(limit: limit * 4).select { |content| reaction_content_quick_accessible?(content) }.first(limit)
      options = popular_contents.filter_map { |content| reaction_option_for(content) }

      (options + built_in_reaction_options).uniq { |option| option[:content] }.first(limit)
    end
  end

  def all_reaction_options
    @all_reaction_options ||= (custom_emoji_reaction_options + built_in_reaction_options).uniq { |option| option[:content] }
  end

  def reaction_option_for(content)
    if custom_emoji = custom_emoji_for(content)
      { content: custom_emoji.shortcode, title: custom_emoji.title, custom_emoji: custom_emoji }
    else
      { content: content, title: REACTIONS.fetch(content, content), custom_emoji: nil }
    end
  end

  def reaction_content_tag(content, custom_emoji: custom_emoji_for(content), **options)
    classes = [ "reaction-content", options.delete(:class) ]

    if custom_emoji&.image&.attached?
      image_tag custom_emoji.image, alt: "", class: [ *classes, "custom-emoji" ], aria: { hidden: "true" }, **options
    else
      tag.span content, class: classes, aria: { hidden: "true" }, **options
    end
  end

  def reaction_title(content)
    reaction_option_for(content)[:title]
  end

  def reaction_picker_cache_key
    @reaction_picker_cache_key ||= [ "reaction-picker", Boost.maximum(:updated_at)&.to_fs(:nsec), CustomEmoji.maximum(:updated_at)&.to_fs(:nsec) ]
  end

  private
    def quick_reaction_options_by_limit
      @quick_reaction_options_by_limit ||= {}
    end

    def reaction_content_quick_accessible?(content)
      content.all_emoji? || custom_emoji_for(content).present?
    end

    def built_in_reaction_options
      REACTIONS.map { |content, title| { content: content, title: title, custom_emoji: nil } }
    end

    def custom_emoji_reaction_options
      custom_emojis.map { |custom_emoji| { content: custom_emoji.shortcode, title: custom_emoji.title, custom_emoji: custom_emoji } }
    end

    def custom_emoji_for(content)
      custom_emoji_by_shortcode[content]
    end

    def custom_emoji_by_shortcode
      @custom_emoji_by_shortcode ||= custom_emojis.index_by(&:shortcode)
    end

    def custom_emojis
      @custom_emojis ||= CustomEmoji.with_attached_image.ordered.to_a
    end
end

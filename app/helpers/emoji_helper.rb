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

  def emoji_menu_icon_tag
    uicon "emoji", size: 18, class: "emoji-menu-icon"
  end

  def emoji_insert_data_for(reaction)
    data = { controller: "emoji-insert", action: "emoji-insert#insert" }

    if reaction[:custom_emoji]
      data[:emoji_insert_html_value] = custom_emoji_editor_tag(reaction[:custom_emoji])
    else
      data[:emoji_insert_content_value] = reaction[:content]
    end

    data
  end

  def custom_emoji_editor_tag(custom_emoji)
    tag.span custom_emoji.shortcode,
      role: "img",
      title: custom_emoji.title,
      class: "custom-emoji custom-emoji--editor",
      aria: { label: custom_emoji.title },
      data: { custom_emoji_shortcode: custom_emoji.shortcode },
      style: "background-image: url(#{url_for(custom_emoji.image)})"
  end

  def render_custom_emojis(html)
    return html unless custom_emojis.any?

    fragment = Nokogiri::HTML5.fragment(html.to_s)
    replace_custom_emoji_text_nodes(fragment)
    fragment.to_html.html_safe
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

    def replace_custom_emoji_text_nodes(node)
      node.children.each do |child|
        if child.text?
          replace_custom_emoji_text_node(child)
        else
          replace_custom_emoji_text_nodes(child) unless child.name.in?(%w[ code pre script style ])
        end
      end
    end

    def replace_custom_emoji_text_node(text_node)
      parts = text_node.text.split(/(:[a-z0-9_+-]+:)/)
      return if parts.one?

      replacement = Nokogiri::HTML5.fragment("")
      replaced = false

      parts.each do |part|
        if custom_emoji = custom_emoji_for(part)
          replacement.add_child Nokogiri::HTML5.fragment(custom_emoji_message_tag(custom_emoji))
          replaced = true
        else
          replacement.add_child Nokogiri::XML::Text.new(part, replacement.document)
        end
      end

      text_node.replace(replacement) if replaced
    end

    def custom_emoji_message_tag(custom_emoji)
      image_tag custom_emoji.image,
        alt: custom_emoji.shortcode,
        title: custom_emoji.title,
        class: "custom-emoji custom-emoji--message"
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

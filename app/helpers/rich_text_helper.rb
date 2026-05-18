module RichTextHelper
  def rich_text_data_actions(composer: true, typing_notifications: true)
    default_actions = []
    default_actions << "trix-change->typing-notifications#start" if typing_notifications
    default_actions << "keydown->composer#submitByKeyboard" if composer

    autocomplete_actions =
      "trix-focus->rich-autocomplete#focus trix-change->rich-autocomplete#search trix-blur->rich-autocomplete#blur"

    [ default_actions.join(" "), autocomplete_actions ].compact_blank.join(" ")
  end
end

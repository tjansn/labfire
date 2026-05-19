module Message::Broadcasts
  def broadcast_create
    if reply?
      broadcast_append_to parent_message, :replies, target: [ parent_message, :replies ]
      parent_message.broadcast_replies_indicator
    else
      broadcast_append_to room, :messages, target: [ room, :messages ]
      ActionCable.server.broadcast("unread_rooms", { roomId: room.id })
    end
  end

  def broadcast_remove
    if reply?
      broadcast_remove_to parent_message, :replies
      parent_message.broadcast_replies_indicator
    else
      broadcast_remove_to room, :messages
    end
  end

  def broadcast_replies_indicator
    broadcast_replace_to room, :messages,
      target: ActionView::RecordIdentifier.dom_id(self, :replies_indicator),
      partial: "messages/replies_indicator", locals: { message: self }
  end
end

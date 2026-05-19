class Messages::ThreadsController < ApplicationController
  include RoomScoped

  layout false

  before_action :set_parent_message

  def show
    @replies = @parent_message.replies.with_creator.with_attachment_details.with_boosts
  end

  private
    def set_parent_message
      anchor = @room.messages.find(params[:message_id])
      @parent_message = anchor.thread_root
    end
end

class Messages::BoostsController < ApplicationController
  before_action :set_message

  def index
  end

  def new
  end

  def create
    @boost = find_or_create_boost

    broadcast_replace if @boost.previously_new_record?
    redirect_to message_boosts_url(@message)
  end

  def destroy
    @boost = @message.boosts.where(booster: Current.user).find(params[:id])
    @boost.destroy!

    broadcast_replace
    redirect_to message_boosts_url(@message), status: :see_other
  end

  private
    def set_message
      @message = Current.user.reachable_messages.find(params[:message_id])
    end

    def boost_params
      params.require(:boost).permit(:content)
    end

    def find_or_create_boost
      @message.boosts.find_or_create_by!(boost_params.merge(booster: Current.user))
    rescue ActiveRecord::RecordNotUnique
      @message.boosts.find_by!(boost_params.merge(booster: Current.user))
    end

    def broadcast_replace
      @message.broadcast_replace_to @message.room, :messages,
        target: helpers.dom_id(@message, :boosts), partial: "messages/boosts/list", locals: { message: @message }, attributes: { maintain_scroll: true }
    end
end

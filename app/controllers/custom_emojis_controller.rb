class CustomEmojisController < ApplicationController
  def create
    @custom_emoji = CustomEmoji.create!(custom_emoji_params.merge(creator: Current.user))

    redirect_back fallback_location: root_url, notice: "Custom emoji :#{@custom_emoji.name}: uploaded"
  rescue ActiveRecord::RecordInvalid => error
    redirect_back fallback_location: root_url, alert: error.record.errors.full_messages.to_sentence
  end

  private
    def custom_emoji_params
      params.require(:custom_emoji).permit(:name, :image)
    end
end

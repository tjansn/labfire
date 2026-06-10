class AddLinkPreviewToMessages < ActiveRecord::Migration[8.2]
  def change
    add_column :messages, :link_preview, :json
  end
end

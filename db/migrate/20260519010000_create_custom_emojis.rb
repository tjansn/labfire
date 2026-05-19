class CreateCustomEmojis < ActiveRecord::Migration[8.2]
  def change
    create_table :custom_emojis do |t|
      t.string :name, null: false
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.timestamps

      t.index :name, unique: true
    end

    change_column :boosts, :content, :string, limit: 64, null: false
  end
end

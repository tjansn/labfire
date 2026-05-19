class AddUniqueIndexToBoosts < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL.squish
      DELETE FROM boosts
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM boosts
        GROUP BY message_id, booster_id, content
      )
    SQL

    add_index :boosts, %i[ message_id booster_id content ], unique: true, name: "index_boosts_on_message_booster_and_content"
  end

  def down
    remove_index :boosts, name: "index_boosts_on_message_booster_and_content"
  end
end

class AddMaxWalkoverToTournaments < ActiveRecord::Migration[6.1]
  def up
    add_column :tournaments, :max_walkover, :integer, null: false, default: 1
  end

  def down
    remove_column :tournaments, :max_walkover
  end
end

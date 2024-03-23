class AddWoCountToTournamentsPlayers < ActiveRecord::Migration[6.1]
  def up
    add_column :tournaments_players, :wo_count, :integer, null: false, default: 0
    execute <<-SQL
ALTER TABLE boards ADD COLUMN walkover BOOLEAN NOT NULL DEFAULT FALSE;
SQL
  end

  def down
    remove_column :tournaments_players, :wo_count
    remove_column :boards, :walkover
  end
end

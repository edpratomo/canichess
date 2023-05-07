class AddBlackListedToTournamentsPlayers < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
ALTER TABLE tournaments_players ADD COLUMN blacklisted BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE standings ADD COLUMN blacklisted BOOLEAN NOT NULL DEFAULT FALSE;
SQL
  end

  def down
    remove_column :tournaments_players, :blacklisted
    remove_column :standings, :blacklisted
  end
end

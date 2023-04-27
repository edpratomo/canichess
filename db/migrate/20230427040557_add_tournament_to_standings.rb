class AddTournamentToStandings < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
ALTER TABLE standings ADD COLUMN tournament_id INTEGER NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE
SQL
  end
  
  def down
    execute <<-SQL
ALTER TABLE standings DROP COLUMN tournament_id
SQL
  end
end

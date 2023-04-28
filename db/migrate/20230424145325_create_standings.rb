class CreateStandings < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
CREATE TABLE standings (
  id SERIAL PRIMARY KEY,
  tournaments_player_id INTEGER NOT NULL REFERENCES tournaments_players(id),
  round INTEGER NOT NULL,
  points NUMERIC(3,1) NOT NULL,
  median NUMERIC(3,1),
  solkoff NUMERIC(3,1),
  cumulative NUMERIC(3,1),
  opposition_cumulative NUMERIC(3,1),
  playing_black INTEGER
);
SQL

    add_index :standings, [:tournaments_player_id, :round], unique: true
  end

  def down
    drop_table :standings
  end
end

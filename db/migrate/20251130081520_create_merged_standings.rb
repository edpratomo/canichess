class CreateMergedStandings < ActiveRecord::Migration[6.1]
  def change
    create_table :merged_standings_configs do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
    add_reference :groups, :merged_standings_config, foreign_key: true, null: true

    execute <<-SQL
CREATE TABLE merged_standings (
  id SERIAL PRIMARY KEY,
  merged_standings_config_id INTEGER NOT NULL REFERENCES merged_standings_configs(id),
  player_id INTEGER NOT NULL REFERENCES players(id),
  points NUMERIC(3,1) NOT NULL DEFAULT 0,
  median NUMERIC(3,1) DEFAULT 0,
  solkoff NUMERIC(3,1) DEFAULT 0,
  cumulative NUMERIC(3,1) DEFAULT 0,
  opposition_cumulative NUMERIC(3,1) DEFAULT 0,
  playing_black INTEGER DEFAULT 0,
  sb NUMERIC(9,2) DEFAULT 0,
  h2h_rank INTEGER DEFAULT 0,
  wins INTEGER DEFAULT 0
);
SQL
  end
end

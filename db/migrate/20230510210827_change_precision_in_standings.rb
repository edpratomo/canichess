class ChangePrecisionInStandings < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
ALTER TABLE standings ALTER COLUMN opposition_cumulative TYPE NUMERIC(9,1);
ALTER TABLE standings ALTER COLUMN points TYPE NUMERIC(9,1);
ALTER TABLE standings ALTER COLUMN median TYPE NUMERIC(9,1);
ALTER TABLE standings ALTER COLUMN solkoff TYPE NUMERIC(9,1);

ALTER TABLE tournaments_players ALTER COLUMN points TYPE NUMERIC(9,1);
SQL
  end
end

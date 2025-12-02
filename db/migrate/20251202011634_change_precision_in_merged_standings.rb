class ChangePrecisionInMergedStandings < ActiveRecord::Migration[6.1]
  def change
    execute <<-SQL
ALTER TABLE merged_standings ALTER COLUMN opposition_cumulative TYPE NUMERIC(9,1);
ALTER TABLE merged_standings ALTER COLUMN points TYPE NUMERIC(9,1);
ALTER TABLE merged_standings ALTER COLUMN median TYPE NUMERIC(9,1);
ALTER TABLE merged_standings ALTER COLUMN solkoff TYPE NUMERIC(9,1);
ALTER TABLE merged_standings ALTER COLUMN cumulative TYPE NUMERIC(9,1);

ALTER TABLE standings ALTER COLUMN cumulative TYPE NUMERIC(9,1);
SQL
  end
end

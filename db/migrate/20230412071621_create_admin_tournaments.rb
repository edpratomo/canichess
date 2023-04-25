class CreateAdminTournaments < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
CREATE TABLE tournaments (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  rounds INTEGER NOT NULL,
  completed_round INTEGER NOT NULL DEFAULT 0,
  modified_by TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT clock_timestamp() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT clock_timestamp() NOT NULL
);
SQL
  end
  
  def down
    drop_table :tournaments
  end
end

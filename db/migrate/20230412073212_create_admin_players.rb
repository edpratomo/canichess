class CreateAdminPlayers < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
CREATE TABLE players (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  rating INTEGER NOT NULL DEFAULT 1200,
  modified_by TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT clock_timestamp() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT clock_timestamp() NOT NULL
);  
SQL
  end
  
  def down
    drop_table :players
  end
end

class CreateAdminTournaments < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
CREATE TABLE tournaments (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
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

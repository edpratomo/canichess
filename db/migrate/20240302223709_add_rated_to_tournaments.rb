class AddRatedToTournaments < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
ALTER TABLE tournaments ADD COLUMN rated BOOLEAN NOT NULL DEFAULT FALSE;

SQL
  end

  def down
    remove_column :tournaments, :rated
  end
end

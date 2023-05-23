class ChangeDefaultRating < ActiveRecord::Migration[6.1]
  def change
    execute <<-SQL
ALTER TABLE players ALTER COLUMN rating SET DEFAULT 1500;
SQL
  end
end

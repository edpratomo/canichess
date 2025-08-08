class AddSbToStandings < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
ALTER TABLE standings ADD COLUMN sb NUMERIC(9,2);
SQL
  end

  def down
    execute <<-SQL
ALTER TABLE standings DROP COLUMN sb;
SQL
  end
end

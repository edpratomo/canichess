class AddSbToStandings < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
ALTER TABLE standings ADD COLUMN sb NUMERIC(9,1);
SQL
  end
end

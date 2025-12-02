class AddColumnToMergedStandings < ActiveRecord::Migration[6.1]
  def change
    add_column :merged_standings, :blacklisted, :boolean, null: false, default: false
  end
end

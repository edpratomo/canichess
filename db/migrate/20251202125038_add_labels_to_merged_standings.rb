class AddLabelsToMergedStandings < ActiveRecord::Migration[6.1]
  def change
    add_column :merged_standings, :labels, :string, array: true, default: []
  end
end

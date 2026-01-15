class AddH2HColumnToMergedStandings < ActiveRecord::Migration[6.1]
  def change
    add_column :merged_standings, :h2h_points, :decimal, precision: 9, scale: 1
    add_column :merged_standings, :h2h_cluster, :integer
    remove_column :merged_standings, :h2h_rank, :integer
  end
end

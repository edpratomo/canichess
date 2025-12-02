class AddPlayerLabelsToMergedStandingsConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :merged_standings_configs, :player_labels, :string, array: true, default: []
  end
end

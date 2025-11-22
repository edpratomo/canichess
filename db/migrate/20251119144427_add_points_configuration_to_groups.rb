class AddPointsConfigurationToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :win_point, :decimal, precision: 3, scale: 1, default: 1.0
    add_column :groups, :draw_point, :decimal, precision: 3, scale: 1, default: 0.5
    add_column :groups, :bye_point, :decimal, precision: 3, scale: 1, default: 1.0
  end
end

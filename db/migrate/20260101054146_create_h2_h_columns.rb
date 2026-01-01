class CreateH2HColumns < ActiveRecord::Migration[6.1]
  def change
    add_column :standings, :h2h_points, :decimal, precision: 9, scale: 1
    add_column :standings, :h2h_cluster, :integer
  end
end

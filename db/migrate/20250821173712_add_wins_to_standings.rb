class AddWinsToStandings < ActiveRecord::Migration[6.1]
  def change
    add_column :standings, :wins, :integer, default: 0
  end
end

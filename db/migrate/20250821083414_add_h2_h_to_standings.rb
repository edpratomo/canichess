class AddH2HToStandings < ActiveRecord::Migration[6.1]
  def change
    add_column :standings, :h2h_rank, :integer
  end
end

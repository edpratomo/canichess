class AddBipartiteMatchingToTournaments < ActiveRecord::Migration[6.1]
  def change
    add_column :tournaments, :bipartite_matching, :integer, array: true, default: []
  end
end

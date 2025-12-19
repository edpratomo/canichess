class RemoveColumnsFromTournaments < ActiveRecord::Migration[6.1]
  def change
    remove_column :tournaments, :bipartite_matching
    remove_column :tournaments, :rounds
    remove_column :tournaments, :completed_round
    remove_column :tournaments, :system
  end
end

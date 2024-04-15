class AddUniqueIndexToTournamentsPlayers < ActiveRecord::Migration[6.1]
  def change
    add_index :tournaments_players, [:tournament_id, :player_id], unique: true
  end
end

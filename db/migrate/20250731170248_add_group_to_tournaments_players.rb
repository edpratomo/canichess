class AddGroupToTournamentsPlayers < ActiveRecord::Migration[6.1]
  def change
    add_reference :tournaments_players, :group, foreign_key: true, null: true
  end
end

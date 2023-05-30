class AddStartEndRatingToTournamentsPlayers < ActiveRecord::Migration[6.1]
  def change
    add_column :tournaments_players, :start_rating, :integer
    add_column :tournaments_players, :end_rating, :integer
  end
end

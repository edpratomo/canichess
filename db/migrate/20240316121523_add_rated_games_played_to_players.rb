class AddRatedGamesPlayedToPlayers < ActiveRecord::Migration[6.1]
  def change
    add_column :players, :rated_games_played, :integer, null: false, default: 0
  end
end

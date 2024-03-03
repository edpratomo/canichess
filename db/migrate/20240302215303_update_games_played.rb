class UpdateGamesPlayed < ActiveRecord::Migration[6.1]
  def change
    Tournament.all[1..].each do |tourney|
      tourney.tournaments_players.each do |t_player|
        games_played = t_player.games.reject {|e| e.contains_bye? }.size
        t_player.player.update!(games_played: t_player.games_played + games_played)
      end
    end
  end
end

module Admin::TournamentsPlayersHelper
  def same_player?(player_1, player_2)
    return false if [player_1, player_2].any?(&:nil?)
    player_1 == player_2
  end
end

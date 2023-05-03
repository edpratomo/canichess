module Admin::BoardsHelper
  def points(tournament_player, round)
    return '' if round < 2
    return '' unless tournament_player
    "(#{tournament_player.standings.find_by(round: round - 1).points})"
  end
end

module Admin::BoardsHelper
  def points(tournament_player, round)
    return '' if round < 2
    return '' unless tournament_player
    "(#{tournament_player.standings.find_by(round: round - 1).points})"
  end

  def disable_finalize_round
    button_tag("Finalize this round", id: "finalize_enabled", class: "btn btn-block btn-primary btn-lg", style: "display: none", data: { confirm: "Are you sure?" }) +
    button_tag("Finalize this round", id: "finalize_disabled", class: "btn btn-block btn-secondary btn-lg disabled", disabled: true)
  end

  def enable_finalize_round
    button_tag("Finalize this round", id: "finalize_enabled", class: "btn btn-block btn-primary btn-lg", data: { confirm: "Are you sure?" }) +
    button_tag("Finalize this round", id: "finalize_disabled", class: "btn btn-block btn-secondary btn-lg disabled", disabled: true, style: "display: none")
  end

  def disable_delete_round
    button_tag("Delete this round", class: "btn btn-block btn-danger btn-lg", style: "display: none", data: { confirm: "Are you sure?" }) +
    button_tag("Delete this round", class: "btn btn-block btn-secondary btn-lg disabled", disabled: true, data: { confirm: "Are you sure?" })
  end

  def enable_delete_round
    button_tag("Delete this round", id: "delete_enabled", class: "btn btn-block btn-danger btn-lg", data: { confirm: "Are you sure?" }) +
    button_tag("Delete this round", id: "delete_disabled", class: "btn btn-block btn-secondary btn-lg disabled", style: "display: none", disabled: true, data: { confirm: "Are you sure?" })
  end
end

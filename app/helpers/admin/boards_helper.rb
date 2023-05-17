module Admin::BoardsHelper
  def points(tournament_player, round)
    return '' if round < 2
    return '' unless tournament_player
    "(#{tournament_player.standings.find_by(round: round - 1).points})"
  end

  def disable_finalize_round
    raw('<td>') +
    button_tag("Finalize this round", id: "finalize_enabled", class: "btn btn-block btn-primary btn-lg", style: "display: none", data: { confirm: "Are you sure?" }) +
    raw('</td><td class="text-center">') +
    button_tag("Finalize this round", id: "finalize_disabled", class: "btn btn-block btn-secondary btn-lg disabled", disabled: true) +
    raw('</td>')
  end

  def enable_finalize_round
    raw('<td>') +
    button_tag("Finalize this round", id: "finalize_enabled", class: "btn btn-block btn-primary btn-lg", data: { confirm: "Are you sure?" }) +
    raw('</td><td>') +
    button_tag("Finalize this round", id: "finalize_disabled", class: "btn btn-block btn-secondary btn-lg disabled", disabled: true, style: "display: none") +
    raw('</td>')
  end

  def disable_delete_round
    raw('<td style="width: 1%">') +
    button_tag("Delete this round", class: "btn btn-block btn-danger btn-lg", style: "display: none", data: { confirm: "Are you sure?" }) +
    raw('</td><td class="text-center">') +
    button_tag("Delete this round", class: "btn btn-block btn-secondary btn-lg disabled", disabled: true, data: { confirm: "Are you sure?" }) +
    raw('</td>')
  end

  def enable_delete_round
    raw('<td>') +
    button_tag("Delete this round", id: "delete_enabled", class: "btn btn-block btn-danger btn-lg", data: { confirm: "Are you sure?" }) +
    raw('</td><td>') +
    button_tag("Delete this round", id: "delete_disabled", class: "btn btn-block btn-secondary btn-lg disabled", style: "display: none", disabled: true, data: { confirm: "Are you sure?" }) +
    raw('</td>')
  end

  def enable_standings
    raw('<td>') +
    button_tag("Standings", class: "btn btn-block btn-success btn-lg") +
    raw('</td>')
  end

  def disable_standings
    raw('<td>') +
    button_tag("Standings", class: "btn btn-block btn-secondary btn-lg disabled", disabled: true) +
    raw('</td>')
  end
end

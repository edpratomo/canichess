module ApplicationHelper
  def chess_result val
    case val
    when "white"
      "1 - 0"
    when "black"
      "0 - 1"
    when "draw"
      raw("&#189; - &#189;")
    when "noshow"
      "0 - 0"
    else
      ''
    end
  end

  def blacklisted_icon tournaments_player
    if tournaments_player.blacklisted
      raw('<i class="fa fa-ban" aria-hidden="true" style="color:red"></i>')
    end
  end

  def winner_icon rank
    case rank
    when 1
      raw('<i class="fa fa-regular fa-trophy" aria-hidden="true" style="color:#FFD700"></i>')
    when 2
      raw('<i class="fa fa-regular fa-trophy" aria-hidden="true" style="color:#C0C0C0"></i>')
    when 3
      raw('<i class="fa fa-regular fa-trophy" aria-hidden="true" style="color:#CD7F32"></i>')
    else
      ''
    end
  end

  def breadcrumb_items active_idx, paths
    items = ['<ol class="breadcrumb float-sm-right">']
    links.each_with_index do |link,idx|
      items.push '<li class="breadcrumb-item' + (idx == active_idx ? ' active">' : '">') + link + '</li>'
    end
    items.push("</ol>")
    return items.join("\n")
  end

  def front_page_button tournament
    return '' unless tournament
    if tournament.completed_round == tournament.rounds
      link_to('Check out the Final Standings', standings_path(tournament.completed_round), class: "btn btn-primary btn-lg", role: "button")
    elsif tournament.current_round > 0
      link_to("Check out pairings for Round #{tournament.current_round}", pairings_path(tournament.current_round), 
              class: "btn btn-primary btn-lg", role: "button")
    end
  end

  def rating_badge tournament_player
    delta = if tournament_player.start_rating and tournament_player.end_rating
      tournament_player.end_rating - tournament_player.start_rating
    end
    return unless delta
    if delta > 0
      raw %Q(<span class="badge bg-info float-right">+ #{delta}</span>)
    elsif delta < 0
      raw %Q(<span class="badge bg-danger float-right">- #{delta.abs}</span>)
    else
      raw %Q(<span class="badge bg-light float-right">+ #{delta}</span>)
    end
  end
end

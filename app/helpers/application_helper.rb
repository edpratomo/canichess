module ApplicationHelper
  def simul_result simul
    total_participants_score = simul.simuls_players.where("result = color").count +
                               simul.simuls_players.where("result = 'draw'").count * 0.5
    total_completed = simul.simuls_players.where("result IS NOT NULL").count
    result_str = "#{total_completed - total_participants_score} - #{total_participants_score}".
                  gsub(/\.0/, '').gsub(/\.5/, '½')
  end

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
      raw('<i class="fa fa-sign-out" aria-hidden="true" style="color:red"></i>')
    end
  end

  def withdrawn_icon tournaments_player
    if tournaments_player.blacklisted
      raw('<i class="fa fa-sign-out" aria-hidden="true" style="color:red"></i>')
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
      link_to('Check out the Final Standings', standings_tournaments_path(tournament, tournament.completed_round), class: "btn btn-primary btn-lg", role: "button")
    elsif tournament.current_round > 0
      link_to("Check out pairings for Round #{tournament.current_round}", pairings_tournaments_path(tournament, tournament.current_round), 
              class: "btn btn-primary btn-lg", role: "button")
    end
  end

  def front_page_button_for_simul simul
    return '' unless simul
    link_to("Check out the Results", simul_result_path(simul), class: "btn btn-primary btn-lg", role: "button")
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

  def categories_badge tournament_player
    colors = CircularArray.new %w[success warning primary secondary info indigo lightblue navy purple fuschia orange lime teal olive]
    label_colors = tournament_player.tournament.player_labels.inject({}) do |m,o|
      m[o] = colors.next
      m
    end
    labels = tournament_player.labels
    labels_str = labels.inject('') do |m,o|
      m += ' '
      m += %Q(<span class="badge bg-#{label_colors[o]}">#{o}</span>)
      m
    end
    raw(labels_str)
  end

  def events_dropdown
    eventables = PastEvent.all.order(id: :desc).map {|e| e.eventable}
    eventables.map do |eventable|
      if eventable.is_a? Tournament
        {name: eventable.name, url: tournament_path(eventable)}
      else
        {name: eventable.name, url: simul_path(eventable)}
      end
    end
  end
end

class CircularArray < Array
  def initialize(*args)
    @curr_idx = -1
    super(*args)
  end

  def next
    return if self.empty?
    @curr_idx += 1
    @curr_idx = 0 if @curr_idx == self.length
    self[@curr_idx]
  end
end

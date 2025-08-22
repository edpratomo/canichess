module ApplicationHelper
  def link_to_not_playing_player(group, round)
    players_ids = Board.where(group: group, round: round).inject([]) do |m,o|
      m << o.white.id if o.white
      m << o.black.id if o.black
      m
    end

    not_playing_player = group.tournaments_players.reject {|e| players_ids.include?(e.id) }.first
    if not_playing_player
      link_to not_playing_player.player.name, player_tournaments_path(not_playing_player), class: "text-white"
    end
  end

  def simul_score simul
    simul.score.gsub(/\.0/, '').gsub(/\b0\.5/, '½').gsub(/\.5/, '½')
  end

  def simul_result player
    return '' unless player.result
    result_str = case player.result
      when player.color
        '<div class="ribbon bg-success">WON</div>'
      when "draw"
        '<div class="ribbon bg-warning">DRAW</div>'
      else
        '<div class="ribbon bg-primary">LOST</div>'
      end

    result_div =<<EOS
<div class="ribbon-wrapper ribbon">
#{result_str}
</div>
EOS
    raw(result_div)
  end

  def player_result group, t_player, opponent
    return 'x' if t_player == opponent
    return '' unless opponent
    board = Board.where(group: group, white: t_player, black: opponent).first
    result = if board
      case board.result
      when "white"
        "1"
      when "black"
        "0"
      when "draw"
        raw("½")
      when "noshow"
        "0"
      else
        ''
      end
    end
    return result if result

    board = Board.where(group: group, black: t_player, white: opponent).first 
    return '' unless board
    case board.result
    when "white"
      "0"
    when "black"
      "1"
    when "draw"
      raw("½")
    when "noshow"
      "0"
    else
      ''
    end
  end

  def chess_result val, walkover = false
    wo_badge = walkover ? ' <span class="badge bg-danger">WO</span> ' : ''
    case val
    when "white"
      raw("1 - 0" + wo_badge)
    when "black"
      raw(wo_badge + "0 - 1")
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

  def front_page_button tournament, group=nil
    return '' unless tournament
    return '' if tournament.is_round_robin? && group.nil?

    if group
      return '' if group.current_round == 0
      if group.completed_round == group.rounds
        link_to('Check out the Final Standings', group_standings_tournaments_path(tournament, group, group.completed_round), class: "btn btn-primary btn-lg", role: "button")
      elsif group.current_round > 0
        link_to("Check out pairings for Round #{group.current_round}", group_pairings_tournaments_path(tournament, group, group.current_round), 
                class: "btn btn-primary btn-lg", role: "button")
      end
    else
      if tournament.completed_round == tournament.rounds
        link_to('Check out the Final Standings', standings_tournaments_path(tournament, tournament.completed_round), class: "btn btn-primary btn-lg", role: "button")
      elsif tournament.current_round > 0
        link_to("Check out pairings for Round #{tournament.current_round}", pairings_tournaments_path(tournament, tournament.current_round), 
                class: "btn btn-primary btn-lg", role: "button")
      end
    end
  end

  def front_page_button_for_simul simul
    return '' unless simul
    if simul.not_started?
       ''
    else
      link_to("Check out the Results", simul_result_path(simul), class: "btn btn-primary btn-lg", role: "button")
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
        #{id: eventable.id, name: eventable.name, url: tournament_path(eventable),
        # groups: eventable.groups.map do |group|
        #   {id: group.id, name: group.name, url: group_show_tournaments_path(eventable, group)}
        # end
        #}
        if eventable.is_round_robin?
          {id: eventable.id, name: eventable.name, url: tournament_path(eventable),
           groups: eventable.groups.map do |group|
             {id: group.id, name: group.name, url: group_show_tournaments_path(eventable, group)}
           end
          }
        else
          {id: eventable.id, name: eventable.name, url: tournament_path(eventable)}
        end
      else
        {id: eventable.id, name: eventable.name, url: simul_path(eventable)}
      end
    end
  end

  def groups_dropdown groups
    groups.map do |group|
      {id: group.id, name: group.name, url: group_show_tournaments_path(group.tournament, group)}
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

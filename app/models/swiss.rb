class Swiss < Group
  def completed?
    self.completed_round == self.rounds
  end

  def delete_round round
    ActiveRecord::Base.transaction do
      # delete_all: bypass callbacks
      self.boards.where(round: round).delete_all
      # delete standings as well
      #Standing.joins(:tournaments_player).where("round >= ?", round - 1, tournaments_players: { group: self }).delete_all
      Standing.joins(:tournaments_player).where(tournaments_players: { group: self }).where("round >= ?", round - 1).delete_all
    end
  end

  def current_round
    last_board = boards.order(:round).last
    last_board ? last_board.round : 0
  end

  def compute_tiebreaks round=nil
    round ||= completed_round
    t_players = tournaments_players.joins(:standings).where('standings.round': round).order('standings.points': :desc)

    # first pass: cumulative
    t_players.each do |t_player|
      standing = t_player.standings.find_by(round: round)
      # cumulative
      tb_cumulative = t_player.standings.where(round: (1..round).to_a).map(&:points).sum
      standing.update!(cumulative: tb_cumulative)
    end

    t_players.each do |t_player|
      standing = t_player.standings.find_by(round: round)
      opponents_points = t_player.prev_opps.reject(&:nil?).map do |opponent|
        Standing.find_by(tournaments_player: opponent, round: round).points
      end.sort

      # solkoff
      tb_solkoff = opponents_points.sum

      # modified median
      t_player_points = standing.points
      tb_modified_median = if t_player_points == rounds / 2
        opponents_points.shift
        opponents_points.pop
        opponents_points.sum
      elsif t_player_points > rounds / 2
        opponents_points.shift
        opponents_points.sum
      else
        opponents_points.pop
        opponents_points.sum
      end
      
      # opposition cumulative
      tb_opposition_cumulative = t_player.prev_opps.reject(&:nil?).map do |opponent|
        Standing.find_by(tournaments_player: opponent, round: round).cumulative
      end.sum

      Rails.logger.info("standing id: #{standing.id}")
      Rails.logger.info("opposition_cumulative: #{tb_opposition_cumulative}")
      Rails.logger.info("solkoff: #{tb_solkoff}")
      Rails.logger.info("modified median: #{tb_modified_median}")

      # update standing for t_player
      standing.update!(median: tb_modified_median, solkoff: tb_solkoff, opposition_cumulative: tb_opposition_cumulative)
    end
  end

  def finalize_round round=nil
    return if completed_round == rounds # tournament is finished already

    transaction do
      # remove players who lost by WO more than max_walkover
      withdraw_wo_players()

      # check if no pairing has been created yet
      if current_round > 0
        #update!(completed_round: completed_round + 1)
        snapshoot_points()
      else
        # first round, save start_rating for each tournament player
        tournaments_players.each do |t_player|
          t_player.update!(start_rating: t_player.rating)
        end
      end
      if completed_round < rounds
        generate_pairings()
      else
        # final round
        compute_tiebreaks()

        # update ratings for rated tournament
        update_ratings() if self.tournament.rated

        # update total games played by each player
        update_total_games()
      end
    end
    true
  end

  alias :start :finalize_round

  # create snapshots of every player for a specific round
  def snapshoot_points round=nil
    return if current_round < 1
    tournaments_players.each do |t_player|
      standing = Standing.find_or_create_by(tournaments_player: t_player, round: current_round)
      standing.update!(tournament: self.tournament, points: t_player.points, playing_black: t_player.playing_black, blacklisted: t_player.blacklisted)
    end
  end

  def sorted_standings round=nil
    round ||= completed_round
    # 13.1.3.1 Joining Nested Associations (Single Level)
    self.tournament.standings.joins(tournaments_player: :player).
      where('tournaments_players.group_id': self.id, round: round).
              order(blacklisted: :asc, points: :desc, median: :desc, solkoff: :desc, cumulative: :desc, 
                    playing_black: :desc, 'tournaments_players.start_rating': :desc, 'players.name': :asc)
  end

  def sorted_merged_standings
    return [] unless merged_standings_config

    merged_standings_config.merged_standings.joins(:player).
      order('blacklisted ASC, points DESC, median DESC, solkoff DESC, cumulative DESC, playing_black DESC, players.name ASC')
  end

  private
  def withdraw_wo_players
    tournaments_players.where('wo_count > ?', self.tournament.max_walkover).each do |t_player|
      t_player.update!(blacklisted: true)
    end
  end

  # must add validation that previous round must be completed
  def generate_pairings
    players_list = ActiveRecordPlayersList.new(self)
    pairing = Pairing.new(players_list)
    round = next_round
    # use bipartite for this round?
    use_bipartite_matching = bipartite_matching.any?(round)
    if use_bipartite_matching
      Rails.logger.debug("Using bipartite matching for round #{round}")
    else
      Rails.logger.debug("Using general matching for round #{round}")
    end
    pairing.generate_pairings(use_bipartite_matching) {|idx, w_player, b_player|
      Board.create!(tournament: self.tournament, group: self, number: idx, round: round, white: w_player, black: b_player)
    }
  end

end

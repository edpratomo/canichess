class Tournament < ApplicationRecord
  has_many :boards
  has_many :standings

  # many-to-many players
  has_many :tournaments_players, dependent: :destroy
  has_many :players, through: :tournaments_players

  validate :all_boards_finished, on: :update, if: :completed_round_changed?

  def boards_per_round
    (players.size.to_f / 2).ceil
  end

  def percentage_completion
    return 100 if completed_round == rounds
    return 0 if current_round == 0
    n_boards_per_round = boards_per_round
    total_boards = n_boards_per_round * rounds
    boards_finished_current_round = boards.where(round: current_round).where.not(result: nil).size
    (((n_boards_per_round * completed_round + boards_finished_current_round) * 100) / (n_boards_per_round * rounds)).floor 
  end

  def import_players players_file
    File.foreach(players_file.path).with_index do |line, index|
      name = line.strip
      g_player = Player.find_by(name: name) || Player.create!(name: name)
      unless players.find_by(name: name)
        players << g_player
      end
    end
  end

  def sorted_standings round=nil
    round ||= completed_round
    # 13.1.3.1 Joining Nested Associations (Single Level)
    standings.joins(tournaments_player: :player).where(round: round).
              order(blacklisted: :asc, points: :desc, median: :desc, solkoff: :desc, cumulative: :desc, 
                    playing_black: :desc, 'players.name': :asc)
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

  def finalize_round
    return if completed_round == rounds # tournament is finished already

    transaction do
      # check if no pairing has been created yet
      if current_round > 0
        update!(completed_round: completed_round + 1)
        snapshoot_points
      end
      if completed_round < rounds
        generate_pairings
      else
        # final round
        compute_tiebreaks
      end
    end
    true
  end

  def current_round
    last_board = boards.order(:round).last
    last_board ? last_board.round : 0
  end

  def next_round
    current_round + 1
  end

  # must add validation that previous round must be completed
  def generate_pairings
    # mapping AR instances to MyPlayer instances
    ar_my_players = tournaments_players.where(blacklisted: false).inject({}) do |m,o|
      m[o.id] = MyPlayer.new(o.id, o.name, o.rating, o.points)
      m
    end

    # add excluded players
    ar_my_players.each do |k,my_player|
      t_player = TournamentsPlayer.find(k)
      my_player.exclude = t_player.prev_opps.map {|e| e.nil? ? Swissper::Bye : ar_my_players[e.id] }
    end

    pairs = Swissper.pair(ar_my_players.values, delta_key: :tournament_points)

    round = next_round

    sorted_boards = pairs.sort_by do |pair|
      if pair.any? {|e| not e.is_a? MyPlayer}
        -1
      else
        pair.sum {|e| e.tournament_points}
      end
    end.reverse

    sorted_boards.each_with_index do |pair, idx|
      # convert back to AR instances
      player_1, player_2 = pair.map do |e|
        unless e.is_a? MyPlayer
          nil
        else
          TournamentsPlayer.find(e.ar_id)
        end
      end

      if [player_1, player_2].any? {|e| e.nil?}
        Board.create!(tournament: self, number: idx + 1, round: round, white: player_1, black: player_2)
      else
        # create board pairing for this round, taking into account the player's playing_black
        w_player, b_player = if player_1.playing_black > player_2.playing_black
          [player_1, player_2]
        else
          [player_2, player_1]
        end
        Board.create!(tournament: self, number: idx + 1, round: round, white: w_player, black: b_player)
      end
    end
  end

  # create snapshots of every player for a specific round
  def snapshoot_points
    return if current_round < 1
    tournaments_players.each do |t_player|
      Standing.create!(tournament: self, round: current_round, tournaments_player: t_player, points: t_player.points, 
                       playing_black: t_player.playing_black, blacklisted: t_player.blacklisted)
    end
  end

  def all_boards_finished? round
    not boards.find_by(result: nil, round: round)
  end

  def any_board_finished? round
    boards.where(round:round).where.not(white: nil).where.not(black: nil).where.not(result: nil).size > 0
  end

  alias :start :finalize_round

  protected
  def all_boards_finished
    Rails.logger.debug(">>>>>>> all_boards_finished called")
    if boards.find_by(result: nil, round: completed_round)
      errors.add(:completed_round, "All boards must have finished first")
    end
  end
end

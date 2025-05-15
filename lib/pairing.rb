require 'swissper'
require 'players_list'

module Swissper
  def self.bipartite_pair(players, options = {})
    Pairer.new(options).bipartite_pair(players)
  end

  class Pairer
    def delta(a, b)
      diff = delta_value(a) - delta_value(b)
      # avoid too large difference
      diff = 0 if diff.abs > 400
      # must be non-zero, thus + 1
      # ((delta_value(a) - delta_value(b)) ** 2 ) + 1
      (diff ** 2) + 1
    end

    def bipartite_pair(player_data)
      @player_data = player_data
      bigraph.maximum_weighted_matching.edges.map do |pairing|
        [players[pairing[0]], players[pairing[1]]]
      end
    end

    # for bipartite matching
    def bigraph
      half_number = (players.count.to_f / 2).ceil

      # store the index of each player in the players set
      (0..players.count - 1).each do |idx|
        players[idx].idx = idx
      end

      canichess_players = players.select {|e| %w[alumni student].any?(e.affiliation) }
      rest_of_the_world = players - canichess_players
      excess_num = canichess_players.count - half_number

      if excess_num > 0
        # skip canichess players that are previously paired with canichess
        filtered_canichess_players = canichess_players.reject do |e|
          e.ar_obj.prev_opps.any? {|prev_opp| %w[alumni student].any?(prev_opp.player.affiliation)}
        end

        1.upto(excess_num) do |e|
          this_player = if filtered_canichess_players.count == 0
            canichess_players.delete_at(rand(canichess_players.count))
          else
            rand_player = filtered_canichess_players.delete_at(rand(filtered_canichess_players.count))
            canichess_players.delete(rand_player) { raise "Couldn't find player: #{rand_player}" }
          end
          rest_of_the_world.push(this_player)
        end
      elsif excess_num < 0
        1.upto(excess_num.abs) do |e|
          this_player = rest_of_the_world.delete_at(rand(rest_of_the_world.count))
          canichess_players.push(this_player)
        end
      end

      edges = [].tap do |e|
        canichess_players.each do |player|
          rest_of_the_world.each do |opp|
            e << [player.idx, opp.idx, delta(player,opp)] if permitted?(player, opp)
          end
        end
      end

      #edges = [].tap do |e|
      #  players.each_with_index do |player, i|
      #    players.each_with_index do |opp, j|
      #      e << [i, j, delta(player,opp)] if permitted?(player, opp)
      #    end
      #  end
      #end
      GraphMatching::Graph::WeightedBigraph[*edges]
    end
  end
end

class Pairing
  class PairingError < StandardError; end

  attr_reader :players_list

  def initialize players_list
    @players_list = players_list
  end

  def group_by_points
    players = players_list.get
    group_points = players.inject({}) do |m,o|
      m[o.tournament_points] ||= []
      m[o.tournament_points].push(o)
      m
    end

    sorted_group_points = group_points.keys.sort.reverse.map {|k| group_points[k].sort_by(&:rating).reverse! }

    # create new bye_bracket containing bye_opponent and bye
    bye_bracket = if players.size.odd?
      bye_opponent = find_bye_opponent(sorted_group_points)
      [bye_opponent, Swissper::Bye]
    end

    # process group with odd number of players
    sorted_group_points.each_with_index do |group,idx|
      break if idx == sorted_group_points.size - 1
      if group.size.odd?
        next_group = sorted_group_points[idx + 1]
        next_group.unshift(group.pop)
      end
    end

    sorted_group_points.push(bye_bracket) if bye_bracket
    sorted_group_points
  end

  def generate_pairings(is_bipartite=false, &blk)
    # add excluded players
    players_list.update_exclusion
    
    players = players_list.get
    highest_rating = players.reject {|e| e == Swissper::Bye }.max {|a,b| a.rating <=> b.rating }.rating
    # pp highest_rating

    groups = group_by_points
    # take out bye_bracket if any
    bye_bracket = if players.size.odd?
      groups.pop
    end

    global_pairs = []

    begin
      groups.each_with_index do |group,idx|
        pairs = if is_bipartite
          Swissper.bipartite_pair(group, delta_key: :rating, bye_delta: highest_rating)
        else
          Swissper.pair(group, delta_key: :rating, bye_delta: highest_rating)
        end
        puts "group: #{idx}, size: #{group.size}, pairs: #{pairs.size}"

        if (pairs.size * 2) < group.size
          if idx + 1 >= groups.size
            # upward merging
            puts "upward merging groups: #{idx} to #{idx - 1}"
            groups[idx - 1].concat(groups.delete_at(idx))
          else
            # downward merging
            puts "downward merging groups: #{idx} to #{idx + 1}"
            groups[idx + 1].concat(groups.delete_at(idx))
          end
          global_pairs = []
          raise PairingError
        else
          sorted_boards = pairs.sort do |a,b|
            ary_a = [a.sum {|e| e.tournament_points}, a.max {|aa,bb| aa.rating <=> bb.rating }.rating]
            ary_b = [b.sum {|e| e.tournament_points}, b.max {|aa,bb| aa.rating <=> bb.rating }.rating]

            ary_a <=> ary_b
          end.reverse

          # add to global_pairs
          global_pairs.concat(sorted_boards)
        end
      end
    rescue PairingError
      retry
    end

    global_pairs.push(bye_bracket) if bye_bracket

    global_pairs.each_with_index do |pair, idx|
      # convert back to AR instances
      player_1, player_2 = pair.map do |e|
        unless e.is_a? Swissper::Player
          nil
        else
          if e.respond_to?(:ar_obj)
            e.ar_obj
          else
            e
          end
        end
      end

      if [player_1, player_2].any? {|e| e.nil?}
        blk.call(idx + 1, player_1, player_2)
      else
        # create board pairing for this round, taking into account the player's playing_black
        w_player, b_player = if player_1.playing_black > player_2.playing_black
          [player_1, player_2]
        else
          [player_2, player_1]
        end
        blk.call(idx + 1, w_player, b_player)
      end
    end
  end

  protected
  def find_bye_opponent sorted_group_points
    # start from the last bracket going up
    bye_opponent = sorted_group_points.reverse.each_with_index do |last_sorted_group_points,idx|
      puts "index: #{idx}"
      # find BYE assigned player: lowest points, lowest rating
      found_opponent = last_sorted_group_points.reject {|e| e == Swissper::Bye or e.exclude.any? {|e| e == Swissper::Bye}}
           .sort {|a,b| [a.tournament_points, a.rating] <=> [b.tournament_points, b.rating]}.first

      next unless found_opponent
      if found_opponent
        # remove bye_opponent from its origin group
        found_index = last_sorted_group_points.find_index(found_opponent)
        puts "FOUND BYE opponent: #{found_opponent.name}, index: #{found_index}"
        last_sorted_group_points.delete_at(found_index)
        break found_opponent
      end
    end
  end
end

if $0 == __FILE__
  class TPlayer < Swissper::Player
    attr_accessor :rating, :tournament_points
    attr_reader :name, :id, :playing_black
    
    def initialize id, name, rating, points=0
      @id = id
      @name = name
      @rating = rating
      @tournament_points = points
      @playing_black = 0
      super()
    end
  end
  
  names_txt = <<-EOF 
Adam Johnson
Ben Smith
Charles Brown
David Taylor
Eric Davis
Frank Lee
George Martin
Henry Wilson
Isaac Green
Jack Baker
Kevin Anderson
Liam Roberts
Michael Clark
Nicholas White
Oliver King
Patrick Scott
Quentin Parker
Ryan Cooper
Samuel Carter
Thomas Harris
Vincent Moore
William Turner
Xavier Adams
York Lewis
Zachary Wright
Aaron Mitchell
Brandon Jackson
Cameron Edwards
Daniel Collins
Ethan Brown
Finn Nelson
Gabriel Martinez
Hector Rivera
Ivan Ramirez
Jacob Gomez
Kenneth Flores
Lucas Hernandez
Marcus Johnson
Nathan Martinez
EOF

  names = names_txt.split("\n").map(&:strip).reject(&:empty?)
  prng = Random.new

  idx = 0
#  players = names.inject([]) do |m,name|
#    idx += 1
#    m.push TPlayer.new(idx, name, 1500 + prng.rand(0..50) * 10)
#    m
#  end

  players_list = PlayersList.new
  names.each do |name|
    idx += 1
    players_list.add(TPlayer.new(idx, name, 1500 + prng.rand(0..50) * 10))
  end

#  pp players

  pairing = Pairing.new(players_list)

#  x = pairing.group_by_points(players)
#  pp x

  y = pairing.generate_pairings {|idx, w_player, b_player| 
    pp [w_player ? "#{w_player.name} (#{w_player.rating})" : "BYE", 
        b_player ? "#{b_player.name} (#{b_player.rating})" : "BYE"
       ]
  }
  
end

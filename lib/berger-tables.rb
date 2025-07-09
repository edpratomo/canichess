    # Copyright (c) 2016 Michael Tenetko
    # The MIT License
    # https://opensource.org/licenses/MIT
    #
    # Description:
    # The program calculates Berger tournament tables for any number of participants. 
    # Berger tables are widely used in the planning of round-robin tournaments.
    # The brief description: https://en.wikipedia.org/wiki/Round-robin_tournament

class RR_Tournament
    # rounds    - array of games.
    # n         - number of participants.
    # t         - number of rounds (n - 1).
    # m         - median of rounds (n / 2).

    attr_accessor :rounds, :n, :t, :m, :is_odd

    def initialize(n)
        n = n.to_i
        if n.odd?
            @n = n + 1
            @is_odd = true
        else
            @n = n
            @is_odd = false
        end
        @t = @n - 1
        @m = @n/2
        @rounds = Array.new(@t) {Array.new(@m)}
        @round_counter = 0
        @round_hsh = {}
    end

    def round_number round_str
        unless @round_hsh.has_key?(round_str)
            @round_counter += 1
            @round_hsh[round_str] = @round_counter
        else
            @round_hsh[round_str]
        end
    end

    #
    # First column is formed as follows:
    # For example, N = 8. We write down the first half of numbers on the left side, in the odd lines.
    # Then we write down the second half of numbers on the right side, in the even lines.
    # 1-
    # -5
    # 2-
    # -6
    # 3-
    # -7
    # 4-
    # Then the missing right or left part is filled with the max number (i.e., 8).
    # If N is odd number, the free participant is the one next to N+1
    # (i.e. in each round the whole first column is out of game, taking rest).

    def make_first_row        
        counter_first_half = 0
        counter_second_half = 1
        (1..t).each do |i|    
            if i <= m
                if @is_odd
                    @rounds[counter_first_half][0] = "#{i}"
                    counter_first_half += 2
                else
                    @rounds[counter_first_half][0] = "#{i}-#{n}"
                    counter_first_half += 2
                end
            elsif i > @m and i != @n
                if @is_odd
                    @rounds[counter_second_half][0] = "#{i}"
                    counter_second_half += 2                            
                else
                    @rounds[counter_second_half][0] = "#{n}-#{i}"
                    counter_second_half += 2
                end
            end
        end
    end

    # The other rows are formed as follows (for example, N = 8):
    # Starting from the 2nd column,
    # - the left part is the next number of the previous column, including the first column,
    #   ignoring 8, in the ascending order;
    # - the right part is the previous number of the previous column, except the first column,
    #   ignoring 8, in the descending order.
    # The left part is calculated by methods 'left_increment' and 'left_increment_for_the_last_column'.
    # The right part is calculated by method 'right_decrement'.
    # The resulting matrix is as follows:
    #
    # 1-8    2-7        3-6        4-5        
    # 8-5    6-4        7-3        1-2
    # 2-8    3-1        4-7        5-6    
    # 8-6    7-5        1-4        2-3
    # 3-8    4-2        5-1        6-7
    # 8-7    1-6        2-5        3-4
    # 4-8    5-3        6-2        7-1
    
    def make_other_rows        
        left = 2
        right = @n - 1

        (0..t-1).each do |c|
            (1..m-1).each do |r|
                @rounds[c][r] = "#{left}-#{right}"
                right = right_decrement(right)
                if r < m-1
                    left = left_increment(left)
                elsif r == m-1
                    left = left_increment_for_the_last_column(left)
                end
            end
        end
    end

    def left_increment(n)        
        if n < @n - 1
            n + 1
        elsif n == @n - 1
            1
        end
    end

    def right_decrement(n)        
        if n > 1
            n - 1
        elsif n == 1
            @n - 1
        end
    end

    def left_increment_for_the_last_column(n)        
        if n <= @n - 3
            n + 2
        elsif n == @n - 2
            1
        elsif n == @n - 1
            2
        end
    end    

    def display_array        
        x = @rounds.size
        #y = @rounds[0].size
        x.times do |a_x|        
            @rounds[a_x].each do |game|
                print game, "\t"
            end
            print "\n"
        end
    end

    def get_pairings &blk
        #pairings = []
        @rounds.each do |round|
            round.each do |game|
                white, black = game.split('-')
                blk.call(round_number(round), white, black) if block_given?
            end
        end
        #pairings
    end
end

if $0 == __FILE__
    def run
        if ARGV.empty?
            n = 8
        else
            n = ARGV[0]
        end
        tournament = RR_Tournament.new(n)
        tournament.make_first_row
        tournament.make_other_rows
        tournament.display_array
        tournament.get_pairings do |round, white, black|
            puts "Round: #{round}, White: #{white}, Black: #{black}"
        end
    end

    run
end

def random_result
    prng = Random.new
    rand_result = prng.rand(3)

  case rand_result
  when 0
    "white"
  when 1
    "black"
  when 2
    "draw"
  end
end

def random_result2(white_rating, black_rating)
  # Calculate win probability for white based on rating difference
  rating_diff = white_rating - black_rating
  white_win_prob = 1.0 / (1.0 + 10.0 ** (-rating_diff / 400.0))
  
  prng = Random.new
  rand_value = prng.rand
  
  # Probability thresholds
  if rand_value < white_win_prob * 0.8  # 80% of calculated probability for wins
    "white"
  elsif rand_value < white_win_prob * 0.8 + (1 - white_win_prob) * 0.8  # Black win
    "black"
  else
    "draw"
  end
end

group_id = ARGV.shift
gr = if group_id
  Group.find(group_id)
else
  Group.last
end

next_round = gr.next_round

curr_round = next_round - 1

exit if curr_round == 0

boards = gr.boards.where(round: curr_round)
boards.each do |board|
  board.update!(result: random_result2(board.white.rating, board.black.rating)) if board.result.nil?
end

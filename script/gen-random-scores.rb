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

tournament_id = ARGV.shift
tr = if tournament_id
  Tournament.find(tournament_id)
else
  Tournament.last
end

next_round = tr.next_round

curr_round = next_round - 1

exit if curr_round == 0

boards = tr.boards.where(round: curr_round)
boards.each do |board|
  board.update!(result: random_result) if board.result.nil?
end

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
  board.update!(result: random_result) if board.result.nil?
end

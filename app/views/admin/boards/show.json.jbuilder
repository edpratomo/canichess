json.set! :tournament do
  json.set! :all_completed, @board.tournament.all_boards_finished?(@board.round)
end
json.set! :group do
  json.set! :all_completed, @board.group.all_boards_finished?(@board.round)
end

tournament_id = ARGV.shift
tr = if tournament_id
  Tournament.find(tournament_id)
else
  Tournament.last
end

tr.start

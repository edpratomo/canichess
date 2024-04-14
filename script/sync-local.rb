require 'optparse'

op_options = [
  ['--host', '-H HOST', "source host",
    lambda { |val| $HOST = val }
  ],
  ['--tournament-id', '-t TID', "tournament ID",
    lambda { |val| $TID = val }
  ],
]

opts = OptionParser.new do |opts|
  op_options.each { |args| opts.on(*args) }
  opts.parse!(ARGV)
end

$HOST ||= "https://canichess.herokuapp.com"

tr = if $TID
  Tournament.find($TID.to_i)
else
  Tournament.last
end

curr_round = tr.current_round
completed_round = tr.completed_round

pp curr_round

if completed_round > 0
  standings_json = %x[curl -s -X GET #{$HOST}/home/#{completed_round}/standings.json]
  standings = JSON.parse(standings_json)

  unless standings["error"]
    print "Syncing standings.. "
    Standing.upsert_all(standings)
    puts "Done."
  end

  last_round_pairings_json = %x[curl -s -X GET #{$HOST}/home/#{completed_round}/pairings.json]
  last_round_pairings = JSON.parse(last_round_pairings_json)
  
  unless last_round_pairings["error"]
    print "Syncing last completed round.. "
    Board.upsert_all(last_round_pairings)
    puts "Done."
  end
end

if curr_round > completed_round
  curr_round_pairings_json = %x[curl -s -X GET #{$HOST}/home/#{curr_round}/pairings.json]
  curr_round_pairings = JSON.parse(curr_round_pairings_json)
  
  unless curr_round_pairings["error"]
    print "Syncing current round.. "
    Board.upsert_all(curr_round_pairings)
    puts "Done. "
  end
end

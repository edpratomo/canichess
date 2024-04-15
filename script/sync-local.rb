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

fp_tournament_json = %x[curl -s -X GET #{$HOST}/home/tournament.json]
if fp_tournament_json["error"]
  puts "Error retrieving front-page tournament: #{fp_tournament_json["error"]}"
  exit 1
end

fp_tournament = JSON.parse(fp_tournament_json)
if fp_tournament["id"].to_i == tr.id
  puts "FP tournament ID: #{fp_tournament["id"] doesn't match your tournament ID: #{tr.id}"
  exit 1
end

curr_round = fp_tournament["current_round"].to_i
completed_round = fp_tournament["completed_round"].to_i

puts "Current round: #{curr_round}"

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

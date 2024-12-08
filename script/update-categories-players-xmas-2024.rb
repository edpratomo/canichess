tr = Tournament.last

tr.update(player_labels: ["junior", "canisian"])

canichess = tr.tournaments_players.select {|tp| tp.player.affiliation == "alumni" or tp.player.affiliation == "student" }.map {|tp| tp.id}

juniors = [
154,
156,
159,
163,

168,
169,
170,

173,
174,
175,
176,
177,
178,
179,
180,
181,
183,
186,
187,
188,

]

both = canichess.intersection(juniors)

#pp both

canichess.each do |sid|
  TournamentsPlayer.find(sid).update!(labels: ["canisian"])
end

juniors.each do |jid|
  TournamentsPlayer.find(jid).update!(labels: ["junior"])
end

both.each do |bid|
  TournamentsPlayer.find(bid).update!(labels: ["canisian", "junior"])
end

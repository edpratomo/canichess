tr = Tournament.last

tr.update(player_labels: ["junior", "senior", "alumni", "student"])

alumni = tr.tournaments_players.select {|tp| tp.player.affiliation == "alumni"}.map {|tp| tp.id}
students =  tr.tournaments_players.select {|tp| tp.player.affiliation == "student" }.map {|tp| tp.id}

seniors = [
222,
220,
226,
234,
227,
255,
223,
253,
219,
252,
259,
239,

]

juniors = [
274,
236,
266,
279,
269,
233,
283,
275,
264,
267,
260,
254,
263,

231,
238,
273,
242,
284,
287,
276,
243,
278,
285,
240,
286,
247,
251,
288,
249,
244,
246,
280,
256,
277,
289,
272,
250,
237,
257,
290
]

students_juniors = students.intersection(juniors)
alumni_seniors = alumni.intersection(seniors)

alumni.each do |aid|
  TournamentsPlayer.find(aid).update!(labels: ["alumni"])
end

students.each do |sid|
  TournamentsPlayer.find(sid).update!(labels: ["student"])
end

seniors.each do |sid|
  TournamentsPlayer.find(sid).update!(labels: ["senior"])
end

juniors.each do |jid|
  TournamentsPlayer.find(jid).update!(labels: ["junior"])
end

students_juniors.each do |bid|
  TournamentsPlayer.find(bid).update!(labels: ["student", "junior"])
end

alumni_seniors.each do |bid|
  TournamentsPlayer.find(bid).update!(labels: ["alumni", "senior"])
end

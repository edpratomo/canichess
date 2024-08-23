canichess = [
134,
126,
132,
144,
127,
128,
121,
139,
145,
136,
146,
125,
119,
130,
133
]

juniors = [
143,
148,
151,
120,
150,
124,
138,
149,
147,
137,
142,
122,
123,

134,
144,
127,
130,
145,
136,
146,
133
]

both = canichess.intersection(juniors)

#tr = Tournament.find(3)
canichess.each do |sid|
  TournamentsPlayer.find(sid).update!(labels: ["canisian"])
end

juniors.each do |jid|
  TournamentsPlayer.find(jid).update!(labels: ["junior"])
end

both.each do |bid|
  TournamentsPlayer.find(bid).update!(labels: ["canisian", "junior"])
end

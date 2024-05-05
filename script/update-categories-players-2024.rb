seniors = [
  110,
  53,
  96,
  57,
  59,
  54,

  108,
  77,
  104,
  56,
]

juniors = [
  60,
  69,
  70,
  72,
  74,
  90,
  97,
  91,
  92,
  98, 
  103,
  109,
  111,
  112,
  82,
  95,
  86,
  105,
  58,
  71,
  93,
  78,
  55,
  113,
  68,
  84,
  102,
  88,
  66,
  106,
  85,
  73,
  61,
  89,
  83
]

#tr = Tournament.find(3)
seniors.each do |sid|
  TournamentsPlayer.find(sid).update!(labels: ["senior"])
end

juniors.each do |jid|
  TournamentsPlayer.find(jid).update!(labels: ["junior"])
end

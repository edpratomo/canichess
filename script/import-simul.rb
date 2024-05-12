
simul = Simul.first
simul ||= Simul.create!(name: "CCE CCAD 2023 Simultaneous Display", simulgivers: "FM Andrean Susilodinata",
                        date: '2023-05-27', location: 'Kolese Kanisius')

names_str = <<-EOF
Irwan Ariston Napitupulu, black, white
Daniel Dirgantara, white, black
Suryono Slamet, black, white
Rafael Darian Kapuangan, white, draw
William John Widjaja, black, white
Edwin Pratomo, white, draw
Daniel Sahalatua Pardosi, black, black
Hendraji Surya Santosa, white, black
Jan Adiar Malik, black, black
Kenneth Lelono, white, black

Martin Hartono, black, white
Alexander Yanuar Wijaya, white, black
Sebastian Eldino Lesmana, black, white
Calista Michaela Yeoh, white, black
Dimas Pulung Wicaksono, black, white
Naro Hugo Boaz Siahaan, white, black
Jefferson Aviel Winata, black, draw
Aurelius Berwyn Huang, white, black
David Irawan, black, white
Lionel Gunawan, white, black

Yehezkiel Ethan Sudjatma, black, white
Sutjipto Susilo, white, draw
Stanley Sujudi, black, white
Castiel Marvel Bestari, white, black
Donald Emanuel Possumah, black, white
Francis Xavier, white, black
Joseph Wirajendi, black, white
Robert Rasidy, white, black
Immanuel Satrio Dewo, black, white
Nathanael Budihardja, white, black
EOF

lines = names_str.split("\n").reject {|e| e.empty?}.compact
pp lines

lines.each do |line|
  name, color, result = line.split(",").map {|e| e.strip}
  pl = Player.find_by(name: name)
  unless pl
    puts "not found: #{name}"
    pl = Player.create(name: name)
  end
  SimulsPlayer.create!(simul: simul, player: pl, color: color, result: result)
end

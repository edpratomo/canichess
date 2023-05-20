# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# create first devise user
unless User.first
  fullname, username, email, password = ENV['DEVISE_FIRST_USER'].split(",").map(&:strip)
  user = User.new(fullname: fullname, username: username, email: email, password: password, password_confirmation: password)
  user.save(validate: false)
end

tournament_name = ENV['TOURNAMENT'] || "Springfield Cup"
number_of_rounds = ENV['ROUNDS'] || ENV['ROUND'] || 5
names_file = ENV['INPUT']

tourney = Tournament.create(name: tournament_name, rounds: number_of_rounds)

names_txt = if names_file
  File.read(names_file)
elsif ENV['RAILS_ENV'] == "development"
  <<-EOF 
Adam Johnson
Ben Smith
Charles Brown
David Taylor
Eric Davis
Frank Lee
George Martin
Henry Wilson
Isaac Green
Jack Baker
Kevin Anderson
Liam Roberts
Michael Clark
Nicholas White
Oliver King
Patrick Scott
Quentin Parker
Ryan Cooper
Samuel Carter
Thomas Harris
Vincent Moore
William Turner
Xavier Adams
York Lewis
Zachary Wright
Aaron Mitchell
Brandon Jackson
Cameron Edwards
Daniel Collins
Ethan Brown
Finn Nelson
Gabriel Martinez
Hector Rivera
Ivan Ramirez
Jacob Gomez
Kenneth Flores
Lucas Hernandez
Marcus Johnson
Nathan Martinez
EOF
else
  ''
end

names = names_txt.split("\n").map(&:strip).reject(&:empty?)

names.each do |name|
  player = Player.create(name: name)
  tourney.players << player
end

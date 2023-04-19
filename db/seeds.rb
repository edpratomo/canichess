# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

tourney = Tournament.create(name: "Springfield Cup")

names_txt = <<-EOF
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

names = names_txt.split("\n").map(&:strip).reject(&:empty?)

names.each do |name|
  Player.create(name: name)
end

Player.all.each do |player|
  tourney.players << player
end

# create first devise user
fullname, username, email, password = ENV['DEVISE_FIRST_USER'].split(",").map(&:strip)
user = User.new(fullname: fullname, username: username, email: email, password: password, password_confirmation: password)
user.save(validate: false)

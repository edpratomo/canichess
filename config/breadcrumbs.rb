crumb :root do
  link "Home", root_path
end

crumb :admin do
  link "Admin Home", admin_path
end

crumb :tournament do |tournament|
  link "Tournament: #{tournament.name}", admin_tournament_path(tournament)
  parent :admin
end

crumb :edit_tournament do |tournament|
  link "Editing Tournament", edit_admin_tournament_path(tournament)
  parent :tournament, tournament
end

crumb :group do |group|
  link group.name, group_show_admin_tournaments_path(group.tournament, group)
  parent :tournament, group.tournament
end

crumb :pairings do |group, round|
  link "Round #{round}", group_admin_boards_path(group.tournament, group, round)
  parent :group, group
end

crumb :standings do |group, round|
  link "Round #{round}", group_admin_standings_path(group.tournament, group, round)
  parent :group, group
end

crumb :edit_group do |group|
  link "Editing #{group.name}", edit_group_admin_tournaments_path(group)
  parent :group, group
end

crumb :simul do |simul|
  link simul.name, admin_simul_path(simul)
  parent :admin
end

crumb :edit_simul do |simul|
  link "Editing #{simul.name}", edit_admin_simul_path(simul)
  parent :simul, simul
end

crumb :tournament_players do |tournament|
  link "Players", tournament_admin_tournaments_players_path(tournament)
  parent :tournament, tournament
end

crumb :tournament_player do |t_player|
  link t_player.name, admin_tournaments_player_path(t_player)
  parent :tournament_players, t_player.tournament
end

crumb :upload_tournament_players do |tournament|
  link "Upload Players", preview_admin_tournaments_players_path(tournament)
  parent :tournament_players, tournament
end

crumb :add_tournament_player do |tournament|
  link "Add Player", new_admin_tournaments_players_path(tournament)
  parent :tournament_players, tournament
end

crumb :simul_players do |simul|
  link "Players", simul_admin_simuls_players_path(simul)
  parent :simul, simul
end

crumb :upload_simul_players do |simul|
  link "Upload Players", preview_admin_simuls_players_path(simul)
  parent :simul_players, simul
end

crumb :players_list do
  link "Players List", admin_players_path
  parent :admin
end

crumb :player do |player|
  link player.name, admin_player_path(player)
  parent :players_list
end

crumb :edit_player do |player|
  link "Editing #{player.name}", edit_admin_player_path(player)
  parent :player, player
end

crumb :sponsor do |sponsor|
  link sponsor.name, admin_sponsor_path(sponsor)
  parent :sponsors_list
end

crumb :edit_sponsor do |sponsor|
  link "Editing #{sponsor.name}", edit_admin_sponsor_path(sponsor)
  parent :sponsor, sponsor
end

crumb :sponsors_list do
  link "Sponsors List", admin_sponsors_path
  parent :admin
end

# If you want to split your breadcrumbs configuration over multiple files, you
# can create a folder named `config/breadcrumbs` and put your configuration
# files there. All *.rb files (e.g. `frontend.rb` or `products.rb`) in that
# folder are loaded and reloaded automatically when you change them, just like
# this file (`config/breadcrumbs.rb`).
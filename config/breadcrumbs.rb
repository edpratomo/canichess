crumb :root do
  link "Home", root_path
end

crumb :admin do
  link "Admin Home", admin_path
end

crumb :tournament do |tournament|
  link tournament.name, admin_tournament_path(tournament)
  parent :admin
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

# If you want to split your breadcrumbs configuration over multiple files, you
# can create a folder named `config/breadcrumbs` and put your configuration
# files there. All *.rb files (e.g. `frontend.rb` or `products.rb`) in that
# folder are loaded and reloaded automatically when you change them, just like
# this file (`config/breadcrumbs.rb`).
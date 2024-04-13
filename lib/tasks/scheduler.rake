desc "This task is called by the Heroku scheduler add-on"
task :update_fide => :environment do
  puts "Updating FIDE data..."
  Player.update_fide
  puts "done."
end

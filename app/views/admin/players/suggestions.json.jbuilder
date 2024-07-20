json.array!(@admin_players) do |player|
  json.extract! player, :name, :email, :id, :rating, :affiliation, :graduation_year
end

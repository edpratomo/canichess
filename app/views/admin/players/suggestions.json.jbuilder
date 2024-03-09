json.array!(@admin_players) do |player|
  json.extract! player, :name, :id, :rating
end

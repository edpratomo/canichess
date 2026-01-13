class TournamentPlayerRegistrar
  def self.call(tournament, player_ids, player_names)
    ActiveRecord::Base.transaction do
      # register players already known in our database
      registered_players = tournament.players.inject({}) {|m,o| m[o.id] = true; m}
      player_ids.map {|e| [e.first.to_i, e[1].to_i]}.
                 reject {|e| registered_players[e.first]}.each do |player_id, group_id|
        tournament.add_player(id: player_id, group: Group.find(group_id))
      end

      # register new players not in our database
      player_names.each do |player_name, group_id|
        tournament.add_player(name: player_name, group: Group.find(group_id))
      end
    end
    true
  rescue ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotFound
    false
  end
end

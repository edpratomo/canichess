class CopyTournamentsAttrs < ActiveRecord::Migration[6.1]
  def change
    tourneys = Tournament.where('id < 71')
    tourneys.each do |e|
      grp = e.groups.first
      grp.update!(completed_round: e.completed_round, bipartite_matching: e.bipartite_matching,
                  max_walkover: e.max_walkover)

      e.tournaments_players.each do |tp|
        tp.update!(group: grp)
      end
    end
  end
end

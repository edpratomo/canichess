class CopyTournamentsAttrs < ActiveRecord::Migration[6.1]
  def change
    execute <<-SQL
DROP TRIGGER IF EXISTS boards_if_modified ON boards;
SQL

    tourneys = Tournament.where('id < 71')
    tourneys.each do |e|
      grp = e.groups.first
      grp.update!(completed_round: e.completed_round, bipartite_matching: e.bipartite_matching,
                  max_walkover: e.max_walkover)

      e.tournaments_players.each do |tp|
        tp.update!(group: grp)
      end

      e.boards.each do |brd|
        brd.update!(group: grp)
      end
    end
  
    execute <<-SQL
CREATE TRIGGER boards_if_modified AFTER DELETE OR UPDATE ON boards FOR EACH ROW EXECUTE PROCEDURE update_points_configurable();
SQL
  end
end

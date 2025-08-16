class AlterUniqueIndexInBoards < ActiveRecord::Migration[6.1]
  def change
    execute <<SQL
DROP INDEX IF EXISTS index_boards_on_tournament_id_and_round_and_number;
CREATE UNIQUE INDEX index_boards_on_tournament_id_and_round_and_number_and_group ON boards (tournament_id, round, number, group_id);
SQL
  end
end

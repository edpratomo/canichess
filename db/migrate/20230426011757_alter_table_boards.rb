class AlterTableBoards < ActiveRecord::Migration[6.1]
  def change
    remove_reference :boards, :white
    remove_reference :boards, :black

    add_reference :boards, :white, foreign_key: {to_table: :tournaments_players}
    add_reference :boards, :black, foreign_key: {to_table: :tournaments_players}
  end
end

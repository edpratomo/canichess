class AddNumberToBoards < ActiveRecord::Migration[6.1]
  def change
    add_column :boards, :number, :integer, null: false
    add_index :boards, [:tournament_id, :round, :number], unique: true
  end
end

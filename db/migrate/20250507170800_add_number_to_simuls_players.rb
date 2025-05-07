class AddNumberToSimulsPlayers < ActiveRecord::Migration[6.1]
  def up
    add_column :simuls_players, :number, :integer, default: 0
  end

  def down
  end
end

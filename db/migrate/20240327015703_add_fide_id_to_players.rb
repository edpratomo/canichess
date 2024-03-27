class AddFideIdToPlayers < ActiveRecord::Migration[6.1]
  def up
    add_column :players, :fide_id, :string
  end

  def down
    remove_column :players, :fide_id
  end
end

class AddFideDataToPlayers < ActiveRecord::Migration[6.1]
  def up
    add_column :players, :fide_data, :text
  end

  def down
    remove_column :players, :fide_data
  end
end

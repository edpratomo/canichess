class AddLocationToTournaments < ActiveRecord::Migration[6.1]
  def up
    add_column :tournaments, :location, :string
    add_column :tournaments, :date, :date
    add_column :tournaments, :description, :text
  end

  def down
    remove_column :tournaments, :date
    remove_column :tournaments, :location
    remove_column :tournaments, :description
  end
end

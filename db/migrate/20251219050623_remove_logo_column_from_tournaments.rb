class RemoveLogoColumnFromTournaments < ActiveRecord::Migration[6.1]
  def change
    remove_column :tournaments, :logo
  end
end

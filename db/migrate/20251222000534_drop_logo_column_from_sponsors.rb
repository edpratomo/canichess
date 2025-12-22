class DropLogoColumnFromSponsors < ActiveRecord::Migration[6.1]
  def change
    remove_column :sponsors, :logo, :string
  end
end

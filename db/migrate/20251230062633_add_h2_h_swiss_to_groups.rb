class AddH2HSwissToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :h2h_swiss, :boolean, default: false
  end
end

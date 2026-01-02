class RenameH2HSwissColumn < ActiveRecord::Migration[6.1]
  def change
    rename_column :groups, :h2h_swiss, :h2h_tb
  end
end

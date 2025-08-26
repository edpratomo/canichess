class AddColumnsToGroup < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :bipartite_matching, :integer, array: true, default: []
    add_column :groups, :max_walkover, :integer, null: false, default: 1
    add_column :groups, :system, :string, null: false, default: "swiss"
    add_column :groups, :rounds, :integer
    add_column :groups, :completed_round, :integer, null: false, default: 0

    change_column_default :groups, :name, from: nil, to: 'Default'

    add_index :groups, :system
  end
end

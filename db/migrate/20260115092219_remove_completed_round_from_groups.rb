class RemoveCompletedRoundFromGroups < ActiveRecord::Migration[6.1]
  def change
    remove_column :groups, :completed_round, :integer, default: 0, null: false
  end
end

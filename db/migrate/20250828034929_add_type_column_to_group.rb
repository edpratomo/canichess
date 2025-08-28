class AddTypeColumnToGroup < ActiveRecord::Migration[6.1]
  def change
    change_column_default :groups, :system, from: 'swiss', to: 'Swiss'
    rename_column :groups, :system, :type
 
    Group.where(tournament_id: 71).update_all(type: 'RoundRobin')
  end
end

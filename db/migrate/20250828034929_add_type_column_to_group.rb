class AddTypeColumnToGroup < ActiveRecord::Migration[6.1]
  def change
    change_column_default :groups, :system, from: 'swiss', to: 'Swiss'
    rename_column :groups, :system, :type
 
    Group.where(tournament_id: 71).update_all(type: 'RoundRobin')

    Tournament.where.not(id: 71).find_each do |tr|
      if tr.groups.count == 0
        Group.create!(tournament: tr, type: 'Swiss')
      end
    end
  end
end

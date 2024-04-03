class AddSimulgiversToSimuls < ActiveRecord::Migration[6.1]
  def change
    add_column :simuls, :simulgivers, :text
  end
end

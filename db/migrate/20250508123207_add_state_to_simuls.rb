class AddStateToSimuls < ActiveRecord::Migration[6.1]
  def change
    add_column :simuls, :status, :integer, default: 0
  end
end

class RemoveGroupDefault < ActiveRecord::Migration[6.1]
  def change
    change_column_default :groups, :name, from: :current_default_value, to: nil
    change_column_default :groups, :type, from: :current_default_value, to: nil
  end
end

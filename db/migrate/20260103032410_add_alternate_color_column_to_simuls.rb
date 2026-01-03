class AddAlternateColorColumnToSimuls < ActiveRecord::Migration[6.1]
  def change
    add_column :simuls, :alternate_color, :integer
    add_column :simuls, :playing_color, :text
  end
end

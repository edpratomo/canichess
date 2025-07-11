class CreateGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :groups do |t|
      t.text :name, null: false
      t.references :tournament, foreign_key: true, null: true
      t.timestamps
    end

    add_reference :boards, :group, foreign_key: true, null: true
  end
end

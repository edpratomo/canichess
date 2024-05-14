class CreateTitles < ActiveRecord::Migration[6.1]
  def up
    create_table :titles do |t|
      t.string :cert_number, null: false, default: ""
      t.string :name, null: false, default: "CCM"
      t.text :remarks
      t.date :awarded_on
      t.references :player, foreign_key: true
      t.timestamps
    end

    add_column :players, :phone, :string, null: false, default: ""
    add_column :players, :email, :string, null: false, default: ""
    add_column :players, :graduation_year, :integer
    add_column :players, :affiliation, :string
    add_column :players, :remarks, :text
    
    execute <<-SQL
ALTER TABLE players ADD CONSTRAINT affiliation_check CHECK ((affiliation = ANY (ARRAY['alumni_relatives'::varchar, 'alumni'::varchar, 'student'::varchar, 'invitee'::varchar, 'staff'::varchar, 'N/A'::varchar])))
SQL
  end

  def down
    drop_table :titles

    execute <<-SQL
ALTER TABLE players DROP CONSTRAINT affiliation_check
SQL

    remove_column :players, :phone
    remove_column :players, :email
    remove_column :players, :graduation_year
    remove_column :players, :affiliation
    remove_column :players, :remarks
  end
end

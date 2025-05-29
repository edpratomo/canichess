class AddSystemToTournaments < ActiveRecord::Migration[6.1]
  def change
    add_column :tournaments, :system, :string, null: false, default: "swiss"
    add_index :tournaments, :system

    reversible do |dir|
      dir.up do
        # Set default system for existing tournaments
        execute <<-SQL.squish
          UPDATE tournaments SET system = 'swiss' WHERE system IS NULL;
        SQL
      end
    end
  end
end

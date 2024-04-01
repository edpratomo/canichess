class AddColorToSimulsPlayers < ActiveRecord::Migration[6.1]
  def up
    add_column :simuls_players, :color, :text,  null: false, default: 'black'
    execute <<-SQL
ALTER TABLE simuls_players ADD CONSTRAINT color_check CHECK ((color = ANY (ARRAY['white'::text, 'black'::text])))
SQL
  end

  def down
    remove_column :simuls_players, :color
  end
end

class AddLogoToTournaments < ActiveRecord::Migration[6.1]
  def up
    add_column :tournaments, :logo, :text
#    add_column :tournaments, :sponsors_logos, :text, array: true, default: []
    add_column :simuls, :logo, :text
#    add_column :simuls, :sponsors_logos, :text, array: true, default: []

    tr2 = Tournament.find_by(id: 2)
    tr2.update!(logo: "logo-canichess-ccad-2023.png") if tr2

    sm1 = Simul.find_by(id: 1)
    sm1.update!(logo: "logo-canichess-ccad-2023.png") if sm1

    tr3 = Tournament.find_by(id: 3)
    tr3.update!(logo: "logo-canichess-ccad-2024.png") if tr3
  end

  def down
    remove_column :tournaments, :logo
#    remove_column :tournaments, :sponsors_logos
    remove_column :simuls, :logo
#    remove_column :simuls, :sponsors_logos
  end
end

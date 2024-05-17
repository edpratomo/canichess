class AddLogoToTournaments < ActiveRecord::Migration[6.1]
  def up
    add_column :tournaments, :logo, :text
    add_column :tournaments, :sponsors_logos, :text, array: true, default: []
    add_column :simuls, :logo, :text
    add_column :simuls, :sponsors_logos, :text, array: true, default: []

    sponsors_2023 = %w[sasa-slide-white.png siree-slide.png coeyoe-slide.png gramps-slide.png
                       meg-cheese-slide.png osk-slide.png]

    sponsors_2024 = %w[sasa-slide-white.png kari-jepang-slide.png coeyoe-slide.png gramps-slide.png
                       meg-cheese-slide.png osk-slide.png]

    tr2 = Tournament.find(2)
    tr2.update!(logo: "logo-canichess-ccad-2023.png", sponsors_logos: sponsors_2023)
    tr3 = Tournament.find(3)
    tr3.update!(logo: "logo-canichess-ccad-2024.png", sponsors_logos: sponsors_2024)
    sm1 = Simul.find(1)
    sm1.update!(logo: "logo-canichess-ccad-2023.png", sponsors_logos: sponsors_2023)
  end

  def down
    remove_column :tournaments, :logo
    remove_column :tournaments, :sponsors_logos
    remove_column :simuls, :logo
    remove_column :simuls, :sponsors_logos
  end
end

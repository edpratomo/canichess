class CreateSponsors < ActiveRecord::Migration[6.1]
  def up
    create_table :sponsors do |t|
      t.string :name, null: false, defaut: ''
      t.string :logo, null: false, default: ''
      t.text :url
      t.text :remark
      t.timestamps
    end

    # many to many
    create_table :events_sponsors do |t|
      t.references :sponsor
      t.references :eventable, polymorphic: true, index: true
    end

    tr2 = Tournament.find(2)
    sm1 = Simul.find(1)
    tr3 = Tournament.find(3)

    sponsors = [
      {
        logo: "sasa-slide-white.png",
        name: "Sasa",
        url: "https://www.sasa.co.id/",
        evs: [tr2, sm1, tr3]
      },
      {
        logo: "siree-slide.png",
        name: "Siree Chess Cafe",
        url: "https://instagram.com/sireechesscafe",
        evs: [tr2, sm1]
      },
      {
        logo: "coeyoe-slide.png",
        name: "Coeyoe Clothing",
        url: "https://instagram.com/coeyoe.id",
        evs: [tr2, sm1, tr3]
      },
      {
        logo: "gramps-slide.png",
        name: "Gramps Cafe",
        url: "https://gramps.id/",
        evs: [tr2, sm1, tr3]
      },
      {
        logo: "meg-cheese-slide.png",
        name: "MEG Cheese",
        url: "https://megcheese.id/",
        evs: [tr2, sm1, tr3]
      },
      {
        logo: "osk-slide.png",
        name: "OSK Green Tea",
        url: "https://www.oskgreentea.id/",
        evs: [tr2, sm1, tr3]
      },
      {
        logo: "kari-jepang-slide.png",
        name: "Sasa Kari Jepang",
        url: "https://www.sasa.co.id/",
        evs: [tr3]
      }
    ]

    sponsors.each do |sponsor|
      sp = Sponsor.create!(name: sponsor[:name], logo: sponsor[:logo], url: sponsor[:url])
      sponsor[:evs].each do |chess_event|
        chess_event.sponsors.push(sp)
      end
    end
  end

  def down
    drop_table :events_sponsors
    drop_table :sponsors
  end
end

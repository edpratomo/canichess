class CreatePastEvents < ActiveRecord::Migration[6.1]
  def up
    create_table :past_events do |t|
      t.references :eventable, polymorphic: true, index: true
      t.timestamps
    end

    tourneys = Tournament.where("id > 1").order(id: :desc)
    simul = Simul.first

    tr1 = Tournament.find_by(id: 2)
    PastEvent.create(eventable: tr1) if tr1
    sm1 = Simul.find_by(id: 1)
    PastEvent.create(eventable: sm1) if sm1
    tr2 = Tournament.find_by(id: 3)
    PastEvent.create(eventable: tr2) if tr2
  end

  def down
    drop_table :past_events
  end
end

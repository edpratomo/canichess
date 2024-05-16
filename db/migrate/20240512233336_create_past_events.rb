class CreatePastEvents < ActiveRecord::Migration[6.1]
  def up
    create_table :past_events do |t|
      t.references :eventable, polymorphic: true, index: true
      t.timestamps
    end

    tourneys = Tournament.where("id > 1").order(id: :desc)
    simul = Simul.first

    tr1 = Tournament.find(2)
    PastEvent.create(eventable: tr1)
    sm1 = Simul.find(1)
    PastEvent.create(eventable: sm1)
    tr2 = Tournament.find(3)
    PastEvent.create(eventable: tr2)
  end

  def down
    drop_table :past_events
  end
end

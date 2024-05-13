class CreatePastEvents < ActiveRecord::Migration[6.1]
  def up
    create_table :past_events do |t|
      t.references :eventable, polymorphic: true, index: true
      t.timestamps
    end
  end

  def down
    drop_table :past_events
  end
end

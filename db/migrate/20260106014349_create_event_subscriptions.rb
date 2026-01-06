class CreateEventSubscriptions < ActiveRecord::Migration[6.1]
  def change
    create_table :event_subscriptions do |t|
      t.references :device_token, null: false, foreign_key: true
      t.references :eventable, polymorphic: true, index: true

      t.timestamps
    end
  end
end

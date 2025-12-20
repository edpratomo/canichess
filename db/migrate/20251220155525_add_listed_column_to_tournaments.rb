class AddListedColumnToTournaments < ActiveRecord::Migration[6.1]
  def change
    add_column :tournaments, :listed, :boolean, null: false, default: false
    add_column :simuls, :listed, :boolean, null: false, default: false
    rename_table :past_events, :listed_events

    ListedEvent.includes(:eventable).each do |e|
      e.eventable.update(listed: true)
    end
  end
end

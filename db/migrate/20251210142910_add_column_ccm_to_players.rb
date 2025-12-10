class AddColumnCcmToPlayers < ActiveRecord::Migration[6.1]
  def change
    add_reference :players, :ccm_awarded_at, foreign_key: { to_table: :past_events }, null: true
  end
end

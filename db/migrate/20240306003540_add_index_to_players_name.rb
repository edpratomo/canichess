class AddIndexToPlayersName < ActiveRecord::Migration[6.1]
  def change
    add_index :players, :name, using: :gist, opclass: :gist_trgm_ops
  end
end

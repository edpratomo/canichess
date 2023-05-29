class AddRatingDeviationToPlayers < ActiveRecord::Migration[6.1]
  def change
    add_column :players, :rating_deviation, :float, null: false, default: 350
    add_column :players, :rating_volatility, :float, null: false, default: 0.06
  end
end

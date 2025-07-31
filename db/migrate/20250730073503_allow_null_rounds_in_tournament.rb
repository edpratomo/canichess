class AllowNullRoundsInTournament < ActiveRecord::Migration[6.1]
  def change
    change_column_null :tournaments, :rounds, true
  end
end

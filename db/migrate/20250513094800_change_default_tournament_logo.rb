class ChangeDefaultTournamentLogo < ActiveRecord::Migration[6.1]
  def change
    change_column_default :tournaments, :logo, from: nil, to: 'logo-canichess-transparent.webp'
  end
end

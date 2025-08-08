class AddDefaultPlayingBlack < ActiveRecord::Migration[6.1]
  def change
    execute <<-SQL
ALTER TABLE standings ALTER COLUMN playing_black SET NOT NULL;
ALTER TABLE standings ALTER COLUMN playing_black SET DEFAULT 0;
SQL
  end
end

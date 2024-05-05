class AddPlayerLabelsToTournaments < ActiveRecord::Migration[6.1]
  def up
    add_column :tournaments, :player_labels, :string, array: true
    add_index :tournaments, :player_labels, using: 'gin'
    add_column :tournaments_players, :labels, :string, array: true
    add_index :tournaments_players, :labels, using: 'gin'

    execute <<-SQL
CREATE FUNCTION check_player_labels() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
DECLARE
  arr2 VARCHAR[];
BEGIN
  arr2 := (SELECT player_labels FROM tournaments WHERE id = NEW.tournament_id);
  IF (SELECT NEW.labels <@ arr2) THEN
    RETURN NEW;
  ELSE
    RAISE EXCEPTION 'tournaments_players.label IS NOT a member of tournament.player_labels';
  END IF;
END;
$$;

CREATE TRIGGER tournaments_players_check_player_labels BEFORE INSERT OR UPDATE ON tournaments_players
  FOR EACH ROW
  EXECUTE FUNCTION check_player_labels();

SQL
  end

  def down
    execute <<-SQL
DROP TRIGGER IF EXISTS tournaments_players_check_player_labels ON tournaments_players;
DROP FUNCTION IF EXISTS check_player_labels();
SQL
    remove_column :tournaments, :player_labels
    remove_column :tournaments_players, :labels
  end
end

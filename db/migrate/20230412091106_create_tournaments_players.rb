class CreateTournamentsPlayers < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
CREATE TABLE tournaments_players (
  id SERIAL PRIMARY KEY,
  tournament_id INTEGER NOT NULL REFERENCES tournaments(id), 
  player_id INTEGER NOT NULL REFERENCES players(id),
  points NUMERIC(3,1) NOT NULL DEFAULT 0
);

--- update points field
CREATE FUNCTION update_points() RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'UPDATE') THEN
    --- substract old results
    IF (OLD.result = 'white') THEN
        UPDATE tournaments_players SET points = points - 1   WHERE tournament_id = OLD.tournament_id AND player_id = OLD.white_id;
    ELSIF (OLD.result = 'black') THEN
        UPDATE tournaments_players SET points = points - 1   WHERE tournament_id = OLD.tournament_id AND player_id = OLD.black_id;
    ELSIF (OLD.result = 'draw') THEN
        UPDATE tournaments_players SET points = points - 0.5 WHERE tournament_id = OLD.tournament_id AND player_id IN (OLD.white_id, OLD.black_id);
    END IF;
    --- update new results
    IF (NEW.result = 'white') THEN
        UPDATE tournaments_players SET points = points + 1   WHERE tournament_id = OLD.tournament_id AND player_id = OLD.white_id;
    ELSIF (NEW.result = 'black') THEN
        UPDATE tournaments_players SET points = points + 1   WHERE tournament_id = OLD.tournament_id AND player_id = OLD.black_id;
    ELSIF (NEW.result = 'draw') THEN
        UPDATE tournaments_players SET points = points + 0.5 WHERE tournament_id = OLD.tournament_id AND player_id IN (OLD.white_id, OLD.black_id);
    END IF;
  ELSIF (TG_OP = 'DELETE') THEN
    IF (OLD.result = 'white') THEN
        UPDATE tournaments_players SET points = points - 1   WHERE tournament_id = OLD.tournament_id AND player_id = OLD.white_id;
    ELSIF (OLD.result = 'black') THEN
        UPDATE tournaments_players SET points = points - 1   WHERE tournament_id = OLD.tournament_id AND player_id = OLD.black_id;
    ELSIF (OLD.result = 'draw') THEN
        UPDATE tournaments_players SET points = points - 0.5 WHERE tournament_id = OLD.tournament_id AND player_id IN (OLD.white_id, OLD.black_id);
    END IF;
  END IF;
  RETURN NULL;
END;
$$;

CREATE TRIGGER boards_if_modified AFTER DELETE OR UPDATE ON boards FOR EACH ROW EXECUTE PROCEDURE update_points();

SQL
  end
  
  def down
    drop_table :tournaments_players
  end
end

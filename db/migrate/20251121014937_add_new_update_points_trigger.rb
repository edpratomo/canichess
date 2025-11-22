class AddNewUpdatePointsTrigger < ActiveRecord::Migration[6.1]
  def change
    execute <<-SQL
--- update points field
CREATE FUNCTION update_points_configurable() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
DECLARE
  win_point DECIMAL(3,1);
  draw_point DECIMAL(3,1);
  bye_point DECIMAL(3,1);
BEGIN
  win_point := (SELECT win_point FROM groups WHERE id = OLD.group_id);
  draw_point := (SELECT draw_point FROM groups WHERE id = OLD.group_id);
  bye_point := (SELECT bye_point FROM groups WHERE id = OLD.group_id);

  IF (TG_OP = 'UPDATE') THEN
  --- substract old results
    IF (OLD.result = 'white') THEN
      IF OLD.black_id IS NULL THEN
        UPDATE tournaments_players SET points = points - bye_point WHERE id = OLD.white_id;
      ELSE
        UPDATE tournaments_players SET points = points - win_point WHERE id = OLD.white_id;
      END IF;
    ELSIF (OLD.result = 'black') THEN
      IF OLD.white_id IS NULL THEN
        UPDATE tournaments_players SET points = points - bye_point WHERE id = OLD.black_id;
      ELSE
        UPDATE tournaments_players SET points = points - win_point   WHERE id = OLD.black_id;
      END IF;
    ELSIF (OLD.result = 'draw') THEN
      UPDATE tournaments_players SET points = points - draw_point WHERE id IN (OLD.white_id, OLD.black_id);
    END IF;
    --- update new results
    IF (NEW.result = 'white') THEN
      IF NEW.black_id IS NULL THEN
        UPDATE tournaments_players SET points = points + bye_point WHERE id = NEW.white_id;
      ELSE
        UPDATE tournaments_players SET points = points + win_point WHERE id = NEW.white_id;
      END IF;
    ELSIF (NEW.result = 'black') THEN
      IF NEW.white_id IS NULL THEN
        UPDATE tournaments_players SET points = points + bye_point WHERE id = NEW.black_id;
      ELSE
        UPDATE tournaments_players SET points = points + win_point   WHERE id = NEW.black_id;
      END IF;
    ELSIF (NEW.result = 'draw') THEN
      UPDATE tournaments_players SET points = points + draw_point WHERE id IN (OLD.white_id, OLD.black_id);
    END IF;
  ELSIF (TG_OP = 'DELETE') THEN
    IF (OLD.result = 'white') THEN
      IF OLD.black_id IS NULL THEN
        UPDATE tournaments_players SET points = points - bye_point WHERE id = OLD.white_id;
      ELSE
        UPDATE tournaments_players SET points = points - win_point WHERE id = OLD.white_id;
      END IF;
    ELSIF (OLD.result = 'black') THEN
      IF OLD.white_id IS NULL THEN
        UPDATE tournaments_players SET points = points - bye_point WHERE id = OLD.black_id;
      ELSE
        UPDATE tournaments_players SET points = points - win_point   WHERE id = OLD.black_id;
      END IF;
    ELSIF (OLD.result = 'draw') THEN
        UPDATE tournaments_players SET points = points - draw_point WHERE id IN (OLD.white_id, OLD.black_id);
    END IF;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS boards_if_modified ON boards;
CREATE TRIGGER boards_if_modified AFTER DELETE OR UPDATE ON boards FOR EACH ROW EXECUTE PROCEDURE update_points_configurable();

SQL
  end
end

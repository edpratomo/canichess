class AddNewUpdatePointsTrigger < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
--- update points field
CREATE FUNCTION update_points_configurable() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
DECLARE
  win_pts DECIMAL(3,1);
  draw_pts DECIMAL(3,1);
  bye_pts DECIMAL(3,1);
BEGIN
  win_pts := (SELECT win_point FROM groups WHERE id = OLD.group_id);
  draw_pts := (SELECT draw_point FROM groups WHERE id = OLD.group_id);
  bye_pts := (SELECT bye_point FROM groups WHERE id = OLD.group_id);

  IF (TG_OP = 'UPDATE') THEN
  --- substract old results
    IF (OLD.result = 'white') THEN
      IF OLD.black_id IS NULL THEN
        UPDATE tournaments_players SET points = points - bye_pts WHERE id = OLD.white_id;
      ELSE
        UPDATE tournaments_players SET points = points - win_pts WHERE id = OLD.white_id;
      END IF;
    ELSIF (OLD.result = 'black') THEN
      IF OLD.white_id IS NULL THEN
        UPDATE tournaments_players SET points = points - bye_pts WHERE id = OLD.black_id;
      ELSE
        UPDATE tournaments_players SET points = points - win_pts   WHERE id = OLD.black_id;
      END IF;
    ELSIF (OLD.result = 'draw') THEN
      UPDATE tournaments_players SET points = points - draw_pts WHERE id IN (OLD.white_id, OLD.black_id);
    END IF;
    --- update new results
    IF (NEW.result = 'white') THEN
      IF NEW.black_id IS NULL THEN
        UPDATE tournaments_players SET points = points + bye_pts WHERE id = NEW.white_id;
      ELSE
        UPDATE tournaments_players SET points = points + win_pts WHERE id = NEW.white_id;
      END IF;
    ELSIF (NEW.result = 'black') THEN
      IF NEW.white_id IS NULL THEN
        UPDATE tournaments_players SET points = points + bye_pts WHERE id = NEW.black_id;
      ELSE
        UPDATE tournaments_players SET points = points + win_pts   WHERE id = NEW.black_id;
      END IF;
    ELSIF (NEW.result = 'draw') THEN
      UPDATE tournaments_players SET points = points + draw_pts WHERE id IN (OLD.white_id, OLD.black_id);
    END IF;
  ELSIF (TG_OP = 'DELETE') THEN
    IF (OLD.result = 'white') THEN
      IF OLD.black_id IS NULL THEN
        UPDATE tournaments_players SET points = points - bye_pts WHERE id = OLD.white_id;
      ELSE
        UPDATE tournaments_players SET points = points - win_pts WHERE id = OLD.white_id;
      END IF;
    ELSIF (OLD.result = 'black') THEN
      IF OLD.white_id IS NULL THEN
        UPDATE tournaments_players SET points = points - bye_pts WHERE id = OLD.black_id;
      ELSE
        UPDATE tournaments_players SET points = points - win_pts   WHERE id = OLD.black_id;
      END IF;
    ELSIF (OLD.result = 'draw') THEN
        UPDATE tournaments_players SET points = points - draw_pts WHERE id IN (OLD.white_id, OLD.black_id);
    END IF;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS boards_if_modified ON boards;
CREATE TRIGGER boards_if_modified AFTER DELETE OR UPDATE ON boards FOR EACH ROW EXECUTE PROCEDURE update_points_configurable();

SQL
  end

  def down
    execute <<-SQL
DROP TRIGGER IF EXISTS boards_if_modified ON boards;
CREATE TRIGGER boards_if_modified AFTER DELETE OR UPDATE ON boards FOR EACH ROW EXECUTE PROCEDURE update_points();
DROP FUNCTION IF EXISTS update_points_configurable();
SQL
  end
end

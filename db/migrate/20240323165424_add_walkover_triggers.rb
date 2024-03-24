class AddWalkoverTriggers < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
CREATE FUNCTION check_result() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF (NEW.result = 'draw' OR NEW.result = 'noshow' OR NEW.result IS NULL) THEN
    IF (NEW.walkover IS TRUE) THEN
      RAISE EXCEPTION 'walkover can only be set for white/black result';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE FUNCTION inc_wo_count(new_round INTEGER, wo_player BIGINT) RETURNS void AS $$
DECLARE
  prev_black INTEGER;
  prev_white INTEGER;
  prev_noshow INTEGER;
BEGIN
  --- check if also WO on the previous round
  prev_black  := (SELECT COUNT(1) FROM boards WHERE round = new_round - 1 AND walkover IS true AND result = 'white' AND black_id = wo_player);
  prev_white  := (SELECT COUNT(1) FROM boards WHERE round = new_round - 1 AND walkover IS true AND result = 'black' AND white_id = wo_player);
  prev_noshow := (SELECT COUNT(1) FROM boards WHERE round = new_round - 1 AND result = 'noshow' AND black_id = wo_player OR white_id = wo_player);

  IF (prev_black > 0 OR prev_white > 0 OR prev_noshow > 0) THEN
    UPDATE tournaments_players SET wo_count = wo_count + 1 WHERE id = wo_player;
  ELSE
    UPDATE tournaments_players SET wo_count = 1 WHERE id = wo_player;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION inc_wo_count_on_noshow() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  PERFORM inc_wo_count(NEW.round, NEW.black_id);
  PERFORM inc_wo_count(NEW.round, NEW.white_id);
  RETURN NULL;
END;
$$;

CREATE FUNCTION inc_wo_count_on_walkover() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
DECLARE
  wo_player BIGINT;
BEGIN
  IF (NEW.result = 'white') THEN
    wo_player := NEW.black_id;
  ELSIF (NEW.result = 'black') THEN
    wo_player := NEW.white_id;
  END IF;
  PERFORM inc_wo_count(NEW.round, wo_player);
  RETURN NULL;
END;
$$;

CREATE FUNCTION dec_wo_count_on_update() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
DECLARE
  wo_player INTEGER;
BEGIN
  RAISE NOTICE 'TG_NAME: %, OP: %, WHEN: %', TG_NAME, TG_OP, TG_WHEN;
  IF (OLD.result = 'white') THEN
    wo_player := OLD.black_id;
  ELSIF (OLD.result = 'black') THEN
    wo_player := OLD.white_id;
  END IF;
  UPDATE tournaments_players SET wo_count = wo_count - 1 WHERE id = wo_player AND wo_count > 0;
  RETURN NULL;
END;
$$;

CREATE FUNCTION dec_wo_count_on_delete() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
DECLARE
  wo_player INTEGER;
BEGIN
  RAISE NOTICE 'TG_NAME: %, OP: %, WHEN: %', TG_NAME, TG_OP, TG_WHEN;
  IF (OLD.result = 'white') THEN
    wo_player := OLD.black_id;
  ELSIF (OLD.result = 'black') THEN
    wo_player := OLD.white_id;
  END IF;
  UPDATE tournaments_players SET wo_count = wo_count - 1 WHERE id = wo_player AND wo_count > 0;
  RETURN NULL;
END;
$$;

CREATE FUNCTION dec_wo_count_on_noshow() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  RAISE NOTICE 'TG_NAME: %, OP: %, WHEN: %', TG_NAME, TG_OP, TG_WHEN;
  UPDATE tournaments_players SET wo_count = wo_count - 1 WHERE id = OLD.black_id AND wo_count > 0;
  UPDATE tournaments_players SET wo_count = wo_count - 1 WHERE id = OLD.white_id AND wo_count > 0;
  RETURN NULL;
END;
$$;

CREATE FUNCTION update_wo_count() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
DECLARE
  prev_black INTEGER;
  prev_white INTEGER;
  wo_player INTEGER;
  winning_player INTEGER;
BEGIN
  RAISE NOTICE 'Executing update_wo_count()';
  IF (NEW.result = 'white') THEN
    wo_player := NEW.black_id;
    winning_player := NEW.white_id;
  ELSIF (NEW.result = 'black') THEN
    wo_player := NEW.white_id;
    winning_player := NEW.black_id;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    PERFORM inc_wo_count(NEW.round, wo_player);
    --- update winning player
    UPDATE tournaments_players SET wo_count = wo_count - 1 WHERE id = winning_player AND wo_count > 0;
  ELSIF TG_OP = 'DELETE' THEN
    IF (OLD.result = 'white') THEN
      wo_player := OLD.black_id;
    ELSIF (OLD.result = 'black') THEN
      wo_player := OLD.white_id;
    END IF;
    UPDATE tournaments_players SET wo_count = wo_count - 1 WHERE id = wo_player AND wo_count > 0;
  END IF;
  RETURN NULL;
END;
$$;

--- prevent walkover is set for draw/noshow result
CREATE TRIGGER boards_check_result BEFORE INSERT OR UPDATE ON boards
  FOR EACH ROW
  EXECUTE FUNCTION check_result();

--- increase WO count if walkover becomes true
CREATE TRIGGER a00_boards_if_walkover_true AFTER UPDATE OF walkover ON boards 
  FOR EACH ROW
  WHEN (NEW.walkover IS true)
  EXECUTE PROCEDURE inc_wo_count_on_walkover();

--- increase WO count if result becomes noshow
CREATE TRIGGER a05_boards_if_noshow AFTER UPDATE OF result ON boards
  FOR EACH ROW
  WHEN (NEW.result = 'noshow')
  EXECUTE PROCEDURE inc_wo_count_on_noshow();

--- decrease WO count if walkover is set to false
CREATE TRIGGER a10_boards_if_walkover_false AFTER UPDATE OF walkover ON boards 
  FOR EACH ROW
  WHEN (NEW.walkover IS false)
  EXECUTE PROCEDURE dec_wo_count_on_update();

--- if result changes while walkover is true
CREATE TRIGGER a20_boards_result_if_walkover_true
  AFTER DELETE OR UPDATE OF result ON boards
  FOR EACH ROW
  WHEN (OLD.walkover IS true)
  EXECUTE PROCEDURE update_wo_count();

--- decrease WO count on boards deletion
CREATE TRIGGER a30_boards_after_delete AFTER DELETE ON boards 
  FOR EACH ROW
  WHEN (OLD.walkover IS true)
  EXECUTE PROCEDURE dec_wo_count_on_delete();

--- decrease WO count if previous result is noshow
CREATE TRIGGER a40_boards_from_noshow AFTER UPDATE OF result ON boards
  FOR EACH ROW
  WHEN (OLD.result = 'noshow')
  EXECUTE PROCEDURE dec_wo_count_on_noshow();

SQL

  end

  def down
    execute <<-SQL
DROP TRIGGER IF EXISTS boards_check_result ON boards;
DROP TRIGGER IF EXISTS a00_boards_if_walkover_true ON boards;
DROP TRIGGER IF EXISTS a05_boards_if_noshow ON boards;
DROP TRIGGER IF EXISTS a10_boards_if_walkover_false ON boards;
DROP TRIGGER IF EXISTS a20_boards_result_if_walkover_true ON boards;
DROP TRIGGER IF EXISTS a30_boards_after_delete ON boards;
DROP TRIGGER IF EXISTS a40_boards_from_noshow ON boards;

DROP FUNCTION IF EXISTS check_result();
DROP FUNCTION IF EXISTS inc_wo_count(integer, bigint);
DROP FUNCTION IF EXISTS inc_wo_count_on_noshow();
DROP FUNCTION IF EXISTS inc_wo_count_on_walkover();
DROP FUNCTION IF EXISTS dec_wo_count_on_update();
DROP FUNCTION IF EXISTS dec_wo_count_on_delete();
DROP FUNCTION IF EXISTS dec_wo_count_on_noshow();
DROP FUNCTION IF EXISTS update_wo_count();
SQL
  
  end
end

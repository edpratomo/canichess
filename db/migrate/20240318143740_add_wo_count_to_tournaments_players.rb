class AddWoCountToTournamentsPlayers < ActiveRecord::Migration[6.1]
  def up
    add_column :tournaments_players, :wo_count, :integer, null: false, default: 0
    execute <<-SQL
ALTER TABLE boards ADD COLUMN walkover BOOLEAN NOT NULL DEFAULT FALSE;

CREATE FUNCTION check_result() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF (NEW.result = 'draw' OR NEW.result = 'noshow') THEN
    IF (NEW.walkover IS TRUE) THEN
      RAISE EXCEPTION 'walkover cannot be set to true for draw or noshow result';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE FUNCTION inc_wo_count() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
DECLARE
  prev_black INTEGER;
  prev_white INTEGER;
  wo_player INTEGER;
BEGIN
  IF (NEW.result = 'white') THEN
    wo_player := NEW.black_id;
  ELSIF (NEW.result = 'black') THEN
    wo_player := NEW.white_id;
  END IF;

  --- check if also WO on the previous round
  prev_black := (SELECT COUNT(1) FROM boards WHERE round = NEW.round - 1 AND walkover IS true AND result = 'white' AND black_id = wo_player);
  prev_white := (SELECT COUNT(1) FROM boards WHERE round = NEW.round - 1 AND walkover IS true AND result = 'black' AND white_id = wo_player);
  IF (prev_black >= 1 OR prev_white >= 1) THEN
    UPDATE tournaments_players SET wo_count = wo_count + 1 WHERE id = wo_player;
  ELSE
    UPDATE tournaments_players SET wo_count = 1 WHERE id = wo_player;
  END IF;
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
    prev_black := (SELECT COUNT(1) FROM boards WHERE round = NEW.round - 1 AND walkover IS true AND result = 'white' AND black_id = wo_player);
    prev_white := (SELECT COUNT(1) FROM boards WHERE round = NEW.round - 1 AND walkover IS true AND result = 'black' AND white_id = wo_player);

    --- update losing player
    IF (prev_black >= 1 OR prev_white >= 1) THEN
      UPDATE tournaments_players SET wo_count = wo_count + 1 WHERE id = wo_player;
    ELSE
      UPDATE tournaments_players SET wo_count = 1 WHERE id = wo_player;
    END IF;

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

--- increase WO count
CREATE TRIGGER a00_boards_if_walkover_true AFTER UPDATE OF walkover ON boards 
  FOR EACH ROW
  WHEN (NEW.walkover IS true)
  EXECUTE PROCEDURE inc_wo_count();

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

SQL
  end

  def down
    execute <<-SQL
DROP TRIGGER IF EXISTS boards_check_result ON boards;
DROP TRIGGER IF EXISTS a00_boards_if_walkover_true ON boards;
DROP TRIGGER IF EXISTS a10_boards_if_walkover_false ON boards;
DROP TRIGGER IF EXISTS a20_boards_result_if_walkover_true ON boards;
DROP TRIGGER IF EXISTS a30_boards_after_delete ON boards;

DROP FUNCTION IF EXISTS check_result();
DROP FUNCTION IF EXISTS inc_wo_count();
DROP FUNCTION IF EXISTS dec_wo_count_on_update();
DROP FUNCTION IF EXISTS dec_wo_count_on_delete();
DROP FUNCTION IF EXISTS update_wo_count();
SQL
    remove_column :tournaments_players, :wo_count
    remove_column :boards, :walkover
  end
end

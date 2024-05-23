class ModifyFpTrigger < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
CREATE FUNCTION update_fp_global() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF (NEW.fp = TRUE) THEN
    IF (TG_TABLE_NAME = 'simuls') THEN
      UPDATE simuls SET fp = FALSE WHERE id != NEW.id AND fp = TRUE;
      UPDATE tournaments SET fp = FALSE WHERE fp = TRUE;
    ELSIF (TG_TABLE_NAME = 'tournaments') THEN
      UPDATE tournaments SET fp = FALSE WHERE id != NEW.id AND fp = TRUE;
      UPDATE simuls SET fp = FALSE WHERE fp = TRUE;
    END IF;    
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS simuls_fp_modified ON simuls;
DROP TRIGGER IF EXISTS tournaments_fp_modified ON tournaments;

CREATE TRIGGER simuls_fp_modified AFTER INSERT OR UPDATE ON simuls FOR EACH ROW EXECUTE PROCEDURE update_fp_global();
CREATE TRIGGER tournaments_fp_modified AFTER INSERT OR UPDATE ON tournaments FOR EACH ROW EXECUTE PROCEDURE update_fp_global();
SQL
  end

  def down
    execute <<-SQL
DROP TRIGGER IF EXISTS simuls_fp_modified ON simuls;
DROP FUNCTION IF EXISTS update_fp_global();
SQL
  end
end

class AddFpToTournaments < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
ALTER TABLE tournaments ADD COLUMN fp BOOLEAN NOT NULL DEFAULT FALSE;

CREATE FUNCTION update_fp() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF (NEW.fp = TRUE) THEN
    UPDATE tournaments SET fp = FALSE WHERE id != NEW.id AND fp = TRUE;
  END IF;
  RETURN NULL;
END;
$$;

CREATE TRIGGER tournaments_fp_modified AFTER INSERT OR UPDATE ON tournaments FOR EACH ROW EXECUTE PROCEDURE update_fp();

SQL

    add_index :tournaments, [:id, :fp]
  end

  def down
    remove_column :tournaments, :fp
  end
end

class CreateAdminSimuls < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
CREATE TABLE simuls (
  id SERIAL PRIMARY KEY,
  fp BOOLEAN NOT NULL DEFAULT FALSE,
  name TEXT NOT NULL,
  description TEXT,
  location TEXT,
  date DATE,
  modified_by TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT clock_timestamp() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT clock_timestamp() NOT NULL
);

CREATE TABLE simuls_players (
  id SERIAL PRIMARY KEY,
  simul_id INTEGER NOT NULL REFERENCES simuls(id),
  player_id INTEGER NOT NULL REFERENCES players(id),
  result TEXT,
  CONSTRAINT boards_result_check CHECK ((result = ANY (ARRAY['white'::text, 'black'::text, 'draw'::text, 'noshow'::text])))
);

CREATE FUNCTION update_fp_simuls() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF (NEW.fp = TRUE) THEN
    UPDATE simuls SET fp = FALSE WHERE id != NEW.id AND fp = TRUE;
  END IF;
  RETURN NULL;
END;
$$;

CREATE TRIGGER simuls_fp_modified AFTER INSERT OR UPDATE ON simuls FOR EACH ROW EXECUTE PROCEDURE update_fp_simuls();
SQL

  end

  def down
    execute <<-SQL
DROP TRIGGER IF EXISTS simuls_fp_modified ON simuls;
DROP FUNCTION IF EXISTS update_fp_simuls();
DROP TABLE IF EXISTS simuls_players;
DROP TABLE IF EXISTS simuls;
SQL
  end
end

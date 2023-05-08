class CreateBoards < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
CREATE TABLE boards (
  id SERIAL PRIMARY KEY,
  tournament_id INTEGER NOT NULL REFERENCES tournaments(id),
  round INTEGER NOT NULL DEFAULT 1,
  white_id INTEGER REFERENCES players(id),
  black_id INTEGER REFERENCES players(id),
  result TEXT,
  CONSTRAINT boards_result_check CHECK ((result = ANY (ARRAY['white'::text, 'black'::text, 'draw'::text, 'noshow'::text])))
);
SQL
  end
  
  def down
    drop_table :boards
  end
end

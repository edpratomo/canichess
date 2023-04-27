class Standing < ApplicationRecord
  belongs_to :tournament
  belongs_to :tournaments_player
end

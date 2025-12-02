class MergedStanding < ApplicationRecord
  belongs_to :merged_standings_config
  belongs_to :player  
end

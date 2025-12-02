class MergedStandingsConfig < ApplicationRecord
  has_many :groups
  has_many :merged_standings
end

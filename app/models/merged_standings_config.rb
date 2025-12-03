class MergedStandingsConfig < ApplicationRecord
  has_many :groups
  has_many :merged_standings

  def all_groups_finished?
    groups.all? { |group| group.is_finished? }
  end
end

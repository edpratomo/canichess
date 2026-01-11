class GroupPresenter
  include Rails.application.routes.url_helpers

  def initialize(group)
    @group = group
  end

  def next_round_path
    group_pairings_tournaments_path(@group.tournament, @group, @group.current_round)
  end
  
  def final_standings_path
    group_standings_tournaments_path(@group.tournament, @group, @group.completed_round)
  end
end

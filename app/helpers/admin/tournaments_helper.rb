module Admin::TournamentsHelper
  def status_badge(tournament)
    if tournament.groups.all?(&:is_finished?)
      raw '<span class="badge badge-info">Completed</span>'
    elsif tournament.boards.count == 0
      raw '<span class="badge badge-warning">Not started yet</span>'
    else
      raw '<span class="badge badge-success">On going</span>'
    end
  end
end

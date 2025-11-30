module Admin::TournamentsHelper
  def status_badge(tournament)
    #if tournament.groups.all?(&:completed?)
      #raw '<span class="badge badge-warning">Not started yet</span>'
    #elsif tournament.completed_round == tournament.rounds
    if false
      raw '<span class="badge badge-info">Completed</span>'
    else
      raw '<span class="badge badge-success">On going</span>'
    end
  end
end

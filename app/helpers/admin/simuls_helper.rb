module Admin::SimulsHelper
  def simul_status_badge(simul)
    if simul.percentage_completion == 0
      raw '<span class="badge badge-warning">No result</span>'
    elsif simul.percentage_completion == 100
      raw '<span class="badge badge-info">Completed</span>'
    else
      raw '<span class="badge badge-success">On going</span>'
    end
  end
end

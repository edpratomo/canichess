module ApplicationHelper
  include RenderGradeComponent

  def active_tab_class(*paths)
    active = false
    paths.each { |path| active ||= current_page?(path) }
    active ? 'active' : ''
  end

  def is_admission_fee_defined?
    AdmissionFee.current
  end
end

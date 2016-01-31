module Application::StyleHelper
  def css_active_row(staging)
    'grey' if staging == true
  end
end

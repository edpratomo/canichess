module ApplicationHelper
  def chess_result val
    case val
    when "white"
      "1 - 0"
    when "black"
      "0 - 1"
    when "draw"
      raw("&#189; - &#189;")
    when "noshow"
      "0 - 0"
    else
      ''
    end
  end

  def blacklisted_icon tournaments_player
    if tournaments_player.blacklisted
      raw('<i class="fa fa-ban" aria-hidden="true" style="color:red"></i>')
    end
  end
end

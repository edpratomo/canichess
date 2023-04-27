module ApplicationHelper
  def chess_result val
    case val
    when "white"
      "1 - 0"
    when "black"
      "0 - 1"
    when "draw"
      raw("&#189; - &#189;")
    else
      ''
    end
  end
end

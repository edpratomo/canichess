module ApplicationHelper
  def chess_result val
    val == "white" ? "1 - 0" : (val == "black" ? "0 - 1" : raw("&#189; - &#189;"))
  end
end

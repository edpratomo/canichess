class Board < ApplicationRecord
  belongs_to :tournament
  belongs_to :white, class_name: 'Player', optional: true
  belongs_to :black, class_name: 'Player', optional: true

  after_create :update_bye_result

  def winner
    return nil if result == 'draw'
    return white if result == 'white'
    return black if result == 'black'
  end

  def update_bye_result
    if [white, black].any? {|e| e.nil? }
      update!(result: white ? 'white' : 'black')
    end
  end

  def result_option_disabled? opt_result
    if [white, black].any? {|e| e.nil? }
      case opt_result
      when 'draw'
        true
      when 'white'
        result == 'black'
      when 'black'
        result == 'white'
      end
    else
      false
    end
  end
end

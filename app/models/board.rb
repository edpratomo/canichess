class Board < ApplicationRecord
  belongs_to :tournament
  belongs_to :white, class_name: 'TournamentsPlayer', optional: true
  belongs_to :black, class_name: 'TournamentsPlayer', optional: true

  after_create :update_bye_result
  after_commit :broadcast_score, on: :update

  def winner
    return nil if result == 'draw'
    return white if result == 'white'
    return black if result == 'black'
  end

  def update_bye_result
    if contains_bye? #[white, black].any? {|e| e.nil? }
      update!(result: white ? 'white' : 'black')
    end
  end

  def contains_bye?
    [white, black].any? {|e| e.nil? }
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

  private
  def broadcast_score
    ActionCable.server.broadcast "score_board", {
      id: id,
      result: result,
      walkover: walkover
    }
  end
end

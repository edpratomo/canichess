class Board < ApplicationRecord
  belongs_to :tournament
  belongs_to :white, class_name: 'TournamentsPlayer', optional: true
  belongs_to :black, class_name: 'TournamentsPlayer', optional: true
  belongs_to :group, optional: true

  after_create :update_bye_result
  after_commit :broadcast_score, on: :update

  before_destroy :check_already_started

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
      walkover: walkover,
      points: %w[win draw bye].map do |e|
          ApplicationController.helpers.remove_fraction(group.send("#{e}_point").to_s)
        end.join('/')
    }
  end

  def check_already_started
    if tournament.is_round_robin?
      if group.boards.where.not(result: nil).any?
        errors.add 'Tournament already started for group #{group.name}. Could not delete player.'
        throw :abort
      end
    elsif tournament.current_round > 0
      errors.add 'Tournament already started. Could not delete player.'
      throw :abort
    end
  end
end

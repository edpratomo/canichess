require 'rails_helper'

RSpec.describe Board, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:tournament) }
    it { is_expected.to belong_to(:white).class_name('TournamentsPlayer').optional }
    it { is_expected.to belong_to(:black).class_name('TournamentsPlayer').optional }
    it { is_expected.to belong_to(:group) }
  end

  describe 'callbacks' do
    describe 'after_create' do
      let(:tournament) { create(:tournament) }
      let(:group) { tournament.groups.first }

      context 'when board contains a bye' do
        let(:player) { create(:player) }
        let!(:tp) { create(:tournaments_player, tournament: tournament, player: player, group: group) }
        let(:board) { create(:board, tournament: tournament, group: group, white: tp, black: nil, result: nil) }

        it 'updates result to white win' do
          expect(board.result).to eq('white')
        end
      end

      context 'when board has both players' do
        let(:player1) { create(:player) }
        let(:player2) { create(:player) }
        let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }
        let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }
        let(:board) { create(:board, tournament: tournament, group: group, white: tp1, black: tp2, result: nil) }

        it 'does not set result automatically' do
          expect(board.result).to be_nil
        end
      end
    end
  end

  describe '#winner' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }

    context 'when result is white' do
      let(:board) { create(:board, tournament: tournament, group: group, white: tp1, black: tp2, result: 'white') }

      it 'returns white player' do
        expect(board.winner).to eq(tp1)
      end
    end

    context 'when result is black' do
      let(:board) { create(:board, tournament: tournament, group: group, white: tp1, black: tp2, result: 'black') }

      it 'returns black player' do
        expect(board.winner).to eq(tp2)
      end
    end

    context 'when result is draw' do
      let(:board) { create(:board, tournament: tournament, group: group, white: tp1, black: tp2, result: 'draw') }

      it 'returns nil' do
        expect(board.winner).to be_nil
      end
    end

    context 'when result is nil' do
      let(:board) { create(:board, tournament: tournament, group: group, white: tp1, black: tp2, result: nil) }

      it 'returns nil' do
        expect(board.winner).to be_nil
      end
    end
  end

  describe '#contains_bye?' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player1) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }

    context 'when black is nil' do
      let(:board) { build(:board, tournament: tournament, group: group, white: tp1, black: nil) }

      it 'returns true' do
        expect(board.contains_bye?).to be true
      end
    end

    context 'when white is nil' do
      let(:board) { build(:board, tournament: tournament, group: group, white: nil, black: tp1) }

      it 'returns true' do
        expect(board.contains_bye?).to be true
      end
    end

    context 'when both players are present' do
      let(:player2) { create(:player) }
      let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }
      let(:board) { build(:board, tournament: tournament, group: group, white: tp1, black: tp2) }

      it 'returns false' do
        expect(board.contains_bye?).to be false
      end
    end
  end

  describe '#update_bye_result' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player) { create(:player) }
    let!(:tp) { create(:tournaments_player, tournament: tournament, player: player, group: group) }

    context 'when white has bye' do
      let(:board) { create(:board, tournament: tournament, group: group, white: tp, black: nil, result: nil) }

      it 'sets result to white' do
        expect(board.result).to eq('white')
      end
    end

    context 'when black has bye' do
      let(:board) { create(:board, tournament: tournament, group: group, white: nil, black: tp, result: nil) }

      it 'sets result to black' do
        expect(board.result).to eq('black')
      end
    end
  end

  describe '#result_option_disabled?' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player) { create(:player) }
    let!(:tp) { create(:tournaments_player, tournament: tournament, player: player, group: group) }

    context 'when board has a bye' do
      let(:board) { create(:board, tournament: tournament, group: group, white: tp, black: nil, result: 'white') }

      it 'disables draw option' do
        expect(board.result_option_disabled?('draw')).to be true
      end

      context 'when result is white' do
        it 'disables black option' do
          expect(board.result_option_disabled?('black')).to be true
        end

        it 'does not disable white option' do
          expect(board.result_option_disabled?('white')).to be false
        end
      end

      context 'when result is black' do
        let(:board) { create(:board, tournament: tournament, group: group, white: nil, black: tp, result: 'black') }

        it 'disables white option' do
          expect(board.result_option_disabled?('white')).to be true
        end

        it 'does not disable black option' do
          expect(board.result_option_disabled?('black')).to be false
        end
      end
    end

    context 'when board has both players' do
      let(:player2) { create(:player) }
      let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }
      let(:board) { create(:board, tournament: tournament, group: group, white: tp, black: tp2, result: nil) }

      it 'does not disable any option' do
        expect(board.result_option_disabled?('white')).to be false
        expect(board.result_option_disabled?('black')).to be false
        expect(board.result_option_disabled?('draw')).to be false
      end
    end
  end

  describe 'broadcast_score callback' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }
    let(:board) { create(:board, tournament: tournament, group: group, white: tp1, black: tp2, result: nil) }

    it 'broadcasts score after update' do
      expect(ActionCable.server).to receive(:broadcast).with('score_board', hash_including(id: board.id))
      board.update(result: 'white')
    end
  end

  describe 'walkover flag' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }

    it 'can be set to true' do
      board = create(:board, tournament: tournament, group: group, white: tp1, black: tp2, result: 'white', walkover: true)
      expect(board.walkover).to be true
    end

    it 'defaults to false' do
      board = create(:board, tournament: tournament, group: group, white: tp1, black: tp2)
      expect(board.walkover).to be false
    end
  end

  describe 'round attribute' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player1) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }

    it 'stores the round number' do
      board = create(:board, tournament: tournament, group: group, white: tp1, black: nil, round: 5)
      expect(board.round).to eq(5)
    end
  end
end

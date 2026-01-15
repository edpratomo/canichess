require 'rails_helper'

RSpec.describe Group, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:boards).dependent(:destroy) }
    it { is_expected.to have_many(:tournaments_players) }
    it { is_expected.to have_many(:players).through(:tournaments_players) }
    it { is_expected.to belong_to(:tournament) }
    it { is_expected.to belong_to(:merged_standings_config).optional }
  end

  describe 'validations' do
    context 'for Swiss system' do
      let(:group) { build(:swiss) }

      it 'validates presence of rounds' do
        group.rounds = nil
        expect(group).not_to be_valid
        expect(group.errors[:rounds]).to be_present
      end
    end
  end

  describe '#completed_round' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player) { create(:player) }
    let!(:tp) { create(:tournaments_player, tournament: tournament, player: player, group: group) }

    context 'when no standings exist' do
      it 'returns 0' do
        expect(group.completed_round).to eq(0)
      end
    end

    context 'when standings exist' do
      let!(:standing1) { create(:standing, tournaments_player: tp, tournament: tournament, round: 1) }
      let!(:standing2) { create(:standing, tournaments_player: tp, tournament: tournament, round: 2) }

      it 'returns the highest round number' do
        expect(group.completed_round).to eq(2)
      end
    end
  end

  describe '#is_finished?' do
    let(:group) { build(:swiss) }

    it 'delegates to completed? method' do
      allow(group).to receive(:completed?).and_return(true)
      expect(group.is_finished?).to be true
    end
  end

  describe '#is_swiss_system?' do
    context 'for Swiss type' do
      let(:group) { build(:swiss) }

      it 'returns true' do
        expect(group.is_swiss_system?).to be true
      end
    end

    context 'for RoundRobin type' do
      let(:group) { build(:round_robin) }

      it 'returns false' do
        expect(group.is_swiss_system?).to be false
      end
    end
  end

  describe '#percentage_completion' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }

    context 'when completed' do
      before do
        allow(group).to receive(:completed_round).and_return(7)
        allow(group).to receive(:rounds).and_return(7)
      end

      it 'returns 100' do
        expect(group.percentage_completion).to eq(100)
      end
    end

    context 'when no rounds started' do
      before do
        allow(group).to receive(:current_round).and_return(0)
      end

      it 'returns 0' do
        expect(group.percentage_completion).to eq(0)
      end
    end

    context 'with partial completion' do
      let(:player1) { create(:player) }
      let(:player2) { create(:player) }
      let(:player3) { create(:player) }
      let(:player4) { create(:player) }
      let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }
      let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }
      let!(:tp3) { create(:tournaments_player, tournament: tournament, player: player3, group: group) }
      let!(:tp4) { create(:tournaments_player, tournament: tournament, player: player4, group: group) }

      before do
        # 4 players = 2 boards per round
        # 7 rounds total
        # 1 round completed, current round has 1/2 boards finished
        allow(group).to receive(:completed_round).and_return(1)
        allow(group).to receive(:current_round).and_return(2)
        allow(group).to receive(:rounds).and_return(7)
        
        create(:board, tournament: tournament, group: group, round: 2, white: tp1, black: tp2, result: 'white')
        create(:board, tournament: tournament, group: group, round: 2, white: tp3, black: tp4, result: nil)
      end

      it 'calculates percentage correctly' do
        percentage = group.percentage_completion
        # (2 boards * 1 completed round + 1 finished board in current round) * 100 / (2 boards * 7 rounds)
        # (2 + 1) * 100 / 14 = 21.42, floor = 21
        expect(percentage).to eq(21)
      end
    end
  end

  describe '#boards_per_round' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }

    before do
      5.times { create(:tournaments_player, tournament: tournament, group: group, player: create(:player)) }
    end

    it 'returns ceil of players divided by 2' do
      expect(group.boards_per_round).to eq(3) # 5 / 2 = 2.5, ceil = 3
    end
  end

  describe '#all_boards_finished?' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }
    let!(:board1) { create(:board, tournament: tournament, group: group, round: 1, white: tp1, black: tp2, result: 'white') }

    context 'when all boards are finished' do
      it 'returns true' do
        expect(group.all_boards_finished?(1)).to be true
      end
    end

    context 'when some boards are not finished' do
      let!(:board2) { create(:board, tournament: tournament, group: group, round: 1, white: tp2, black: tp1, result: nil) }

      it 'returns false' do
        expect(group.all_boards_finished?(1)).to be false
      end
    end
  end

  describe '#any_board_finished?' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }

    context 'when at least one board is finished' do
      let!(:board) { create(:board, tournament: tournament, group: group, round: 1, white: tp1, black: tp2, result: 'white') }

      it 'returns true' do
        expect(group.any_board_finished?(1)).to be true
      end
    end

    context 'when no boards are finished' do
      let!(:board) { create(:board, tournament: tournament, group: group, round: 1, white: tp1, black: tp2, result: nil) }

      it 'returns false' do
        expect(group.any_board_finished?(1)).to be false
      end
    end
  end

  describe '#next_round' do
    let(:group) { build(:swiss) }

    it 'returns current_round + 1' do
      allow(group).to receive(:current_round).and_return(3)
      expect(group.next_round).to eq(4)
    end
  end

  describe 'abstract methods' do
    let(:group) { build(:group) }

    it 'raises NotImplementedError for sufficient_players?' do
      expect { group.sufficient_players? }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for current_round' do
      expect { group.current_round }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for delete_round' do
      expect { group.delete_round(1) }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for finalize_round' do
      expect { group.finalize_round(1) }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for snapshoot_points' do
      expect { group.snapshoot_points(1) }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for compute_tiebreaks' do
      expect { group.compute_tiebreaks(1) }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for sorted_standings' do
      expect { group.sorted_standings }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for sorted_merged_standings' do
      expect { group.sorted_merged_standings }.to raise_error(NotImplementedError)
    end
  end
end

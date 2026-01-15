require 'rails_helper'

RSpec.describe Tournament, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:events_sponsors).dependent(:destroy) }
    it { is_expected.to have_many(:sponsors).through(:events_sponsors) }
    it { is_expected.to have_many(:boards).dependent(:destroy) }
    it { is_expected.to have_many(:standings).dependent(:destroy) }
    it { is_expected.to have_many(:tournaments_players).dependent(:destroy) }
    it { is_expected.to have_many(:players).through(:tournaments_players) }
    it { is_expected.to have_many(:groups).dependent(:destroy) }
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'creates a default group' do
        tournament = create(:tournament)
        expect(tournament.groups.count).to eq(1)
        expect(tournament.groups.first.name).to eq('Default')
        expect(tournament.groups.first.type).to eq('Swiss')
      end
    end

    describe 'before_destroy' do
      context 'when tournament is rated and has completed groups' do
        let(:tournament) { create(:tournament, :rated) }
        let(:group) { tournament.groups.first }

        before do
          # Create actual standings to make the group completed
          player = create(:player)
          tp = create(:tournaments_player, tournament: tournament, group: group, player: player)
          create(:standing, tournaments_player: tp, tournament: tournament, round: group.rounds)
        end

        it 'prevents deletion' do
          expect(group.completed?).to be true
          expect(tournament.groups.any?(&:completed?)).to be true
          expect { tournament.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
        end
      end

      context 'when tournament is not rated' do
        let(:tournament) { create(:tournament) }

        it 'allows deletion' do
          expect { tournament.destroy! }.not_to raise_error
        end
      end
    end
  end

  describe '#only_group' do
    context 'when tournament has one group' do
      let(:tournament) { create(:tournament) }

      it 'returns the first group' do
        expect(tournament.only_group).to eq(tournament.groups.first)
      end
    end

    context 'when tournament has multiple groups' do
      let(:tournament) { create(:tournament) }

      before do
        create(:swiss, tournament: tournament, name: 'Second Group')
      end

      it 'returns nil' do
        expect(tournament.only_group).to be_nil
      end
    end
  end

  describe '#get_results' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }
    let!(:board1) { create(:board, tournament: tournament, group: group, round: 1, white: tp1, black: tp2, result: 'white') }
    let!(:board2) { create(:board, tournament: tournament, group: group, round: 1, white: tp2, black: tp1, result: nil) }

    it 'returns results for completed boards in the round' do
      results = tournament.get_results(1)
      expect(results.size).to eq(1)
      expect(results.first[:id]).to eq(board1.id)
      expect(results.first[:result]).to eq('white')
    end

  end

  describe '#boards_per_round' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }

    before do
      3.times { create(:tournaments_player, tournament: tournament, group: group, player: create(:player)) }
    end

    it 'returns ceil of players divided by 2' do
      expect(tournament.boards_per_round).to eq(2) # 3 / 2 = 1.5, ceil = 2
    end
  end

  describe '#percentage_completion' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }

    context 'when all groups are finished' do
      before do
        allow(tournament.groups).to receive(:all?).and_return(true)
      end

      it 'returns 100' do
        expect(tournament.percentage_completion).to eq(100)
      end
    end

    context 'when no boards exist' do
      it 'returns 0' do
        expect(tournament.percentage_completion).to eq(0)
      end
    end

    context 'with partial completion' do
      before do
        # Set rounds and create standings up to round 2
        group.update!(rounds: 7)
        player1 = create(:player)
        player2 = create(:player)
        tp1 = create(:tournaments_player, tournament: tournament, group: group, player: player1)
        tp2 = create(:tournaments_player, tournament: tournament, group: group, player: player2)
        # Create boards to make percentage_completion work
        create(:board, tournament: tournament, group: group, round: 1, white: tp1, black: tp2, result: 'white')
        create(:board, tournament: tournament, group: group, round: 2, white: tp1, black: tp2, result: 'draw')
        create(:standing, tournaments_player: tp1, tournament: tournament, round: 2)
      end

      it 'returns percentage based on completed rounds' do
        expect(tournament.groups.first.completed_round).to eq(2)
        percentage = tournament.percentage_completion
        expect(percentage).to eq(28) # (2 * 100 / 7).floor
      end
    end
  end

  describe '#delete_player_label_at' do
    let(:tournament) { create(:tournament, player_labels: ['Label1', 'Label2', 'Label3']) }

    it 'deletes the label at the given index' do
      tournament.delete_player_label_at(1)
      expect(tournament.player_labels).to eq(['Label1', 'Label3'])
    end

    it 'saves the tournament' do
      expect(tournament).to receive(:save)
      tournament.delete_player_label_at(1)
    end
  end

  describe '#delete_group_boards' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let!(:board1) { create(:board, tournament: tournament, group: group) }
    let!(:board2) { create(:board, tournament: tournament, group: group) }

    it 'deletes all boards for the group' do
      expect {
        tournament.delete_group_boards(group)
      }.to change { tournament.boards.count }.by(-2)
    end
  end

  describe '#add_player' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }

    context 'with existing player' do
      let(:player) { create(:player) }

      it 'adds the player to the tournament' do
        expect {
          tournament.add_player(id: player.id, group: group)
        }.to change { tournament.players.count }.by(1)
      end

      it 'creates tournaments_player record' do
        expect {
          tournament.add_player(id: player.id, group: group)
        }.to change { TournamentsPlayer.count }.by(1)
      end
    end

    context 'with new player' do
      it 'creates a new player and adds to tournament' do
        expect {
          tournament.add_player(name: 'New Player', group: group)
        }.to change { Player.count }.by(1).and change { tournament.players.count }.by(1)
      end
    end

    context 'without specifying group' do
      it 'uses the only_group' do
        player = create(:player)
        tournament.add_player(id: player.id)
        tp = tournament.tournaments_players.last
        expect(tp.group).to eq(tournament.only_group)
      end
    end
  end

  describe '#withdraw_wo_players' do
    let(:tournament) { create(:tournament, max_walkover: 2) }
    let(:group) { tournament.groups.first }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, group: group, wo_count: 3) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, group: group, wo_count: 1) }

    it 'blacklists players exceeding max walkover' do
      tournament.withdraw_wo_players
      expect(tp1.reload.blacklisted).to be true
      expect(tp2.reload.blacklisted).to be false
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
    let!(:board2) { create(:board, tournament: tournament, group: group, round: 1, white: tp1, black: tp2, result: 'black') }

    context 'when all boards have results' do
      it 'returns true' do
        expect(tournament.all_boards_finished?(1)).to be true
      end
    end

    context 'when some boards have no result' do
      let!(:board3) { create(:board, tournament: tournament, group: group, round: 1, white: tp1, black: tp2, result: nil) }

      it 'returns false' do
        expect(tournament.all_boards_finished?(1)).to be false
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
      let!(:board1) { create(:board, tournament: tournament, group: group, round: 1, white: tp1, black: tp2, result: 'white') }

      it 'returns true' do
        expect(tournament.any_board_finished?(1)).to be true
      end
    end

    context 'when no boards are finished' do
      let!(:board1) { create(:board, tournament: tournament, group: group, round: 1, white: tp1, black: tp2, result: nil) }

      it 'returns false' do
        expect(tournament.any_board_finished?(1)).to be false
      end
    end
  end
end

require 'rails_helper'

RSpec.describe TournamentsPlayer, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:tournament) }
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to have_many(:standings) }
  end

  describe 'callbacks' do
    describe 'before_destroy' do
      let(:tournament) { create(:tournament) }
      let(:group) { tournament.groups.first }
      let(:player) { create(:player) }
      let!(:tp) { create(:tournaments_player, tournament: tournament, player: player, group: group) }

      context 'when tournament has started' do
        let(:player2) { create(:player) }
        let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }
        let!(:board) { create(:board, tournament: tournament, group: group, round: 1, white: tp, black: tp2) }

        before do
          allow(group).to receive(:current_round).and_return(1)
        end

        it 'prevents deletion' do
          expect { tp.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
        end

        it 'adds error message' do
          tp.destroy
          expect(tp.errors.full_messages.first).to include('Tournament already started')
        end
      end

      context 'when tournament has not started' do
        before do
          allow(group).to receive(:current_round).and_return(0)
        end

        it 'allows deletion' do
          expect { tp.destroy! }.not_to raise_error
        end
      end

      context 'for non-Swiss system' do
        let(:round_robin_group) { create(:round_robin, tournament: tournament) }
        let!(:rr_tp) { create(:tournaments_player, tournament: tournament, player: player, group: round_robin_group) }

        it 'allows deletion without checking if started' do
          expect { rr_tp.destroy! }.not_to raise_error
        end
      end
    end
  end

  describe '#prev_opps' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let(:player3) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }
    let!(:tp3) { create(:tournaments_player, tournament: tournament, player: player3, group: group) }

    before do
      create(:board, tournament: tournament, group: group, round: 1, white: tp1, black: tp2, result: 'white')
      create(:board, tournament: tournament, group: group, round: 2, white: tp3, black: tp1, result: 'draw')
    end

    it 'returns all previous opponents' do
      opponents = tp1.prev_opps
      expect(opponents).to include(tp2, tp3)
      expect(opponents.size).to eq(2)
    end

    it 'does not include duplicates' do
      # Create another game against same opponent
      create(:board, tournament: tournament, group: group, round: 3, white: tp1, black: tp2, result: 'draw')
      opponents = tp1.prev_opps
      expect(opponents.count { |o| o == tp2 }).to eq(1)
    end

    context 'when player has no opponents' do
      let(:player4) { create(:player) }
      let!(:tp4) { create(:tournaments_player, tournament: tournament, player: player4, group: group) }

      it 'returns empty array' do
        expect(tp4.prev_opps).to be_empty
      end
    end
  end

  describe '#result_against' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }

    context 'when tp1 played as white and won' do
      before do
        create(:board, tournament: tournament, group: group, white: tp1, black: tp2, result: 'white')
      end

      it 'returns :won' do
        expect(tp1.result_against(tp2)).to eq(:won)
      end

      it 'returns :lost for the opponent' do
        expect(tp2.result_against(tp1)).to eq(:lost)
      end
    end

    context 'when tp1 played as black and won' do
      before do
        create(:board, tournament: tournament, group: group, white: tp2, black: tp1, result: 'black')
      end

      it 'returns :won' do
        expect(tp1.result_against(tp2)).to eq(:won)
      end
    end

    context 'when game was a draw' do
      before do
        create(:board, tournament: tournament, group: group, white: tp1, black: tp2, result: 'draw')
      end

      it 'returns :draw' do
        expect(tp1.result_against(tp2)).to eq(:draw)
        expect(tp2.result_against(tp1)).to eq(:draw)
      end
    end

    context 'when players never met' do
      it 'returns nil' do
        expect(tp1.result_against(tp2)).to be_nil
      end
    end
  end

  describe '#games' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let(:player3) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }
    let!(:tp3) { create(:tournaments_player, tournament: tournament, player: player3, group: group) }

    before do
      create(:board, tournament: tournament, group: group, round: 1, white: tp1, black: tp2, result: 'white')
      create(:board, tournament: tournament, group: group, round: 2, white: tp3, black: tp1, result: 'draw')
      create(:board, tournament: tournament, group: group, round: 3, white: tp2, black: tp3, result: 'black')
    end

    it 'returns all games for the player' do
      games = tp1.games
      expect(games.size).to eq(2)
    end

    it 'orders games by round' do
      games = tp1.games
      expect(games.first.round).to eq(1)
      expect(games.last.round).to eq(2)
    end

    it 'does not include games from other players' do
      games = tp1.games
      expect(games).not_to include(Board.find_by(white: tp2, black: tp3))
    end
  end

  describe '#playing_black' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let(:player3) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: group) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: group) }
    let!(:tp3) { create(:tournaments_player, tournament: tournament, player: player3, group: group) }

    before do
      create(:board, tournament: tournament, group: group, round: 1, white: tp2, black: tp1, result: 'white')
      create(:board, tournament: tournament, group: group, round: 2, white: tp1, black: tp3, result: 'draw')
      create(:board, tournament: tournament, group: group, round: 3, white: tp2, black: tp1, result: 'black')
    end

    context 'without specifying round' do
      it 'returns total number of games played as black' do
        expect(tp1.playing_black).to eq(2)
      end
    end

    context 'with specified round' do
      it 'returns count for that round only' do
        expect(tp1.playing_black(1)).to eq(1)
        expect(tp1.playing_black(2)).to eq(0)
        expect(tp1.playing_black(3)).to eq(1)
      end
    end
  end

  describe 'delegation methods' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player) { create(:player, name: 'John Doe', affiliation: 'student', rating: 1650, games_played: 25, rated_games_played: 20) }
    let!(:tp) { create(:tournaments_player, tournament: tournament, player: player, group: group) }

    describe '#name' do
      it 'returns player name' do
        expect(tp.name).to eq('John Doe')
      end
    end

    describe '#alumni?' do
      context 'when player is alumni' do
        let(:player) { create(:player, :alumni) }

        it 'returns true' do
          expect(tp.alumni?).to be true
        end
      end

      context 'when player is not alumni' do
        it 'returns false' do
          expect(tp.alumni?).to be false
        end
      end
    end

    describe '#student?' do
      context 'when player is student' do
        it 'returns true' do
          expect(tp.student?).to be true
        end
      end

      context 'when player is not student' do
        let(:player) { create(:player, affiliation: 'invitee') }

        it 'returns false' do
          expect(tp.student?).to be false
        end
      end
    end

    describe '#canisian?' do
      context 'when player is student or alumni' do
        it 'returns true' do
          expect(tp.canisian?).to be true
        end
      end

      context 'when player is not canisian' do
        let(:player) { create(:player, affiliation: 'invitee') }

        it 'returns false' do
          expect(tp.canisian?).to be false
        end
      end
    end

    describe '#rating' do
      it 'returns player rating' do
        expect(tp.rating).to eq(1650)
      end
    end

    describe '#games_played' do
      it 'returns player games_played count' do
        expect(tp.games_played).to eq(25)
      end
    end

    describe '#rated_games_played' do
      it 'returns player rated_games_played count' do
        expect(tp.rated_games_played).to eq(20)
      end
    end
  end

  describe '#swiss_system?' do
    let(:tournament) { create(:tournament) }

    context 'when group is Swiss' do
      let(:swiss_group) { create(:swiss, tournament: tournament) }
      let!(:tp) { create(:tournaments_player, tournament: tournament, group: swiss_group, player: create(:player)) }

      it 'returns true' do
        expect(tp.swiss_system?).to be true
      end
    end

    context 'when group is RoundRobin' do
      let(:rr_group) { create(:round_robin, tournament: tournament) }
      let!(:tp) { create(:tournaments_player, tournament: tournament, group: rr_group, player: create(:player)) }

      it 'returns false' do
        expect(tp.swiss_system?).to be false
      end
    end

    context 'when group is nil' do
      let(:player) { create(:player) }
      let(:tp) { build(:tournaments_player, tournament: tournament, group: nil, player: player) }

      it 'returns false' do
        expect(tp.swiss_system?).to be false
      end
    end
  end

  describe 'attributes' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player) { create(:player) }

    it 'stores points' do
      tp = create(:tournaments_player, tournament: tournament, player: player, group: group, points: 5.5)
      expect(tp.points).to eq(5.5)
    end

    it 'stores wo_count (walkover count)' do
      tp = create(:tournaments_player, tournament: tournament, player: player, group: group, wo_count: 2)
      expect(tp.wo_count).to eq(2)
    end

    it 'stores blacklisted status' do
      tp = create(:tournaments_player, tournament: tournament, player: player, group: group, blacklisted: true)
      expect(tp.blacklisted).to be true
    end

    it 'stores start_rating' do
      tp = create(:tournaments_player, tournament: tournament, player: player, group: group, start_rating: 1500)
      expect(tp.start_rating).to eq(1500)
    end

    it 'stores end_rating' do
      tp = create(:tournaments_player, tournament: tournament, player: player, group: group, end_rating: 1550)
      expect(tp.end_rating).to eq(1550)
    end

    it 'stores labels array' do
      tp = create(:tournaments_player, tournament: tournament, player: player, group: group, labels: ['U18', 'Junior'])
      expect(tp.labels).to eq(['U18', 'Junior'])
    end
  end
end

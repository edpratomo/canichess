require 'rails_helper'

RSpec.describe Swiss, type: :model do
  describe 'STI inheritance' do
    it 'is a subclass of Group' do
      expect(Swiss.superclass).to eq(Group)
    end

    it 'has type set to Swiss' do
      swiss = create(:swiss)
      expect(swiss.type).to eq('Swiss')
    end
  end

  describe '#completed?' do
    let(:swiss) { create(:swiss, rounds: 7) }

    context 'when completed_round equals rounds' do
      before do
        player = create(:player)
        tp = create(:tournaments_player, tournament: swiss.tournament, player: player, group: swiss)
        create(:standing, tournaments_player: tp, tournament: swiss.tournament, round: 7)
      end

      it 'returns true' do
        expect(swiss.completed?).to be true
      end
    end

    context 'when completed_round is less than rounds' do
      before do
        player = create(:player)
        tp = create(:tournaments_player, tournament: swiss.tournament, player: player, group: swiss)
        create(:standing, tournaments_player: tp, tournament: swiss.tournament, round: 5)
      end

      it 'returns false' do
        expect(swiss.completed?).to be false
      end
    end
  end

  describe '#sufficient_players?' do
    let(:tournament) { create(:tournament) }
    let(:swiss) { create(:swiss, tournament: tournament, rounds: 5) }

    context 'when enough players for the rounds' do
      before do
        # 2^4 = 16 players needed for 5 rounds
        16.times { create(:tournaments_player, tournament: tournament, group: swiss, player: create(:player)) }
      end

      it 'returns true' do
        expect(swiss.sufficient_players?).to be true
      end
    end

    context 'when not enough players for the rounds' do
      before do
        # Only 10 players, need 16 for 5 rounds
        10.times { create(:tournaments_player, tournament: tournament, group: swiss, player: create(:player)) }
      end

      it 'returns false' do
        expect(swiss.sufficient_players?).to be false
      end
    end
  end

  describe '#delete_round' do
    let(:tournament) { create(:tournament) }
    let(:swiss) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: swiss) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: swiss) }
    let!(:board_r1) { create(:board, tournament: tournament, group: swiss, round: 1, white: tp1, black: tp2, result: 'white') }
    let!(:board_r2) { create(:board, tournament: tournament, group: swiss, round: 2, white: tp1, black: tp2, result: 'draw') }
    let!(:standing_r0) { create(:standing, tournaments_player: tp1, tournament: tournament, round: 0) }
    let!(:standing_r1) { create(:standing, tournaments_player: tp1, tournament: tournament, round: 1) }

    it 'deletes boards for the specified round' do
      expect {
        swiss.delete_round(2)
      }.to change { swiss.boards.where(round: 2).count }.from(1).to(0)
    end

    it 'does not delete boards from other rounds' do
      expect {
        swiss.delete_round(2)
      }.not_to change { swiss.boards.where(round: 1).count }
    end

    it 'deletes standings from specified round onwards' do
      expect {
        swiss.delete_round(2)
      }.to change { Standing.where(tournaments_player: tp1).where('round >= ?', 1).count }.from(1).to(0)
    end
  end

  describe '#current_round' do
    let(:tournament) { create(:tournament) }
    let(:swiss) { tournament.groups.first }

    context 'when no boards exist' do
      it 'returns 0' do
        expect(swiss.current_round).to eq(0)
      end
    end

    context 'when boards exist' do
      let(:player1) { create(:player) }
      let(:player2) { create(:player) }
      let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: swiss) }
      let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: swiss) }
      let!(:board_r1) { create(:board, tournament: tournament, group: swiss, round: 1, white: tp1, black: tp2) }
      let!(:board_r3) { create(:board, tournament: tournament, group: swiss, round: 3, white: tp1, black: tp2) }

      it 'returns the highest round number' do
        expect(swiss.current_round).to eq(3)
      end
    end
  end

  describe '#compute_tiebreaks' do
    let(:tournament) { create(:tournament) }
    let(:swiss) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let(:player3) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: swiss, points: 2.0) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: swiss, points: 1.0) }
    let!(:tp3) { create(:tournaments_player, tournament: tournament, player: player3, group: swiss, points: 0.0) }

    before do
      # Create standings for round 2
      create(:standing, tournaments_player: tp1, tournament: tournament, round: 1, points: 1.0)
      create(:standing, tournaments_player: tp1, tournament: tournament, round: 2, points: 2.0)
      create(:standing, tournaments_player: tp2, tournament: tournament, round: 1, points: 0.5)
      create(:standing, tournaments_player: tp2, tournament: tournament, round: 2, points: 1.0)
      create(:standing, tournaments_player: tp3, tournament: tournament, round: 1, points: 0.0)
      create(:standing, tournaments_player: tp3, tournament: tournament, round: 2, points: 0.0)
      
      # Create games between players
      create(:board, tournament: tournament, group: swiss, round: 1, white: tp1, black: tp2, result: 'white')
      create(:board, tournament: tournament, group: swiss, round: 2, white: tp1, black: tp3, result: 'white')
    end

    it 'calculates cumulative tiebreak' do
      swiss.compute_tiebreaks(2)
      standing = Standing.find_by(tournaments_player: tp1, round: 2)
      expect(standing.cumulative).to eq(3.0) # 1.0 + 2.0
    end

    it 'calculates solkoff tiebreak (sum of opponents points)' do
      swiss.compute_tiebreaks(2)
      standing = Standing.find_by(tournaments_player: tp1, round: 2)
      # tp1 played against tp2 (1.0) and tp3 (0.0)
      expect(standing.solkoff).to eq(1.0)
    end

    it 'calculates opposition cumulative tiebreak' do
      swiss.compute_tiebreaks(2)
      standing = Standing.find_by(tournaments_player: tp1, round: 2)
      # tp1 opponents: tp2 (cumulative: 0.5+1.0=1.5) and tp3 (cumulative: 0+0=0)
      expect(standing.opposition_cumulative).to eq(1.5)
    end
  end

  describe '#snapshoot_points' do
    let(:tournament) { create(:tournament) }
    let(:swiss) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: swiss, points: 2.5, blacklisted: false) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: swiss, points: 1.0, blacklisted: false) }

    before do
      # Create a board so current_round > 0
      create(:board, tournament: tournament, group: swiss, round: 1, white: tp1, black: tp2, result: 'white')
    end

    context 'when current_round is greater than 0' do
      it 'creates standings for current round' do
        expect {
          swiss.snapshoot_points
        }.to change { Standing.count }.by(2)
      end

      it 'saves correct points in standing' do
        swiss.snapshoot_points
        standing = Standing.find_by(tournaments_player: tp1, round: 1)
        expect(standing.points).to eq(2.5)
      end

      it 'saves correct playing_black count' do
        swiss.snapshoot_points
        standing = Standing.find_by(tournaments_player: tp2, round: 1)
        expect(standing.playing_black).to eq(1)
      end

      it 'saves blacklisted status' do
        swiss.snapshoot_points
        standing = Standing.find_by(tournaments_player: tp1, round: 1)
        expect(standing.blacklisted).to be false
      end
    end

    context 'when current_round is 0' do
      before do
        Board.destroy_all
      end

      it 'does not create standings' do
        expect {
          swiss.snapshoot_points
        }.not_to change { Standing.count }
      end
    end
  end

  describe '#sorted_standings' do
    let(:tournament) { create(:tournament) }
    let(:swiss) { tournament.groups.first }
    let(:player1) { create(:player, name: 'Alice') }
    let(:player2) { create(:player, name: 'Bob') }
    let(:player3) { create(:player, name: 'Charlie') }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: swiss, start_rating: 1600) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: swiss, start_rating: 1500) }
    let!(:tp3) { create(:tournaments_player, tournament: tournament, player: player3, group: swiss, start_rating: 1700, blacklisted: true) }
    let!(:standing1) { create(:standing, tournaments_player: tp1, tournament: tournament, round: 1, points: 2.0, median: 5.0, solkoff: 10.0) }
    let!(:standing2) { create(:standing, tournaments_player: tp2, tournament: tournament, round: 1, points: 2.0, median: 4.0, solkoff: 9.0) }
    let!(:standing3) { create(:standing, tournaments_player: tp3, tournament: tournament, round: 1, points: 3.0, median: 6.0, solkoff: 12.0, blacklisted: tp3.blacklisted) }

    it 'orders by blacklisted first (false before true)' do
      standings = swiss.sorted_standings(1)
      # puts standings.inspect
      expect(standings.first.tournaments_player).to eq(tp1) # not blacklisted, highest tiebreaks
      expect(standings.last.tournaments_player).to eq(tp3) # blacklisted
    end

    it 'orders by points descending within non-blacklisted players' do
      standings = swiss.sorted_standings(1)
      non_blacklisted = standings.reject { |s| s.blacklisted }
      expect(non_blacklisted.first.points).to be >= non_blacklisted.last.points
    end

    it 'uses tiebreaks for same points' do
      standings = swiss.sorted_standings(1)
      # tp1 and tp2 both have 2.0 points, but tp1 has better median
      non_blacklisted = standings.reject { |s| s.blacklisted }
      expect(non_blacklisted.first.tournaments_player).to eq(tp1)
      expect(non_blacklisted.last.tournaments_player).to eq(tp2)
    end
  end

  describe '#finalize_round' do
    let(:tournament) { create(:tournament, max_walkover: 2) }
    let(:swiss) { tournament.groups.first }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, player: player1, group: swiss, wo_count: 0) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, player: player2, group: swiss, wo_count: 3) }

    context 'when tournament is not finished' do
      before do
        allow(swiss).to receive(:current_round).and_return(0)
        allow(swiss).to receive(:rounds).and_return(7)
      end

      it 'withdraws players exceeding max walkover' do
        swiss.finalize_round
        expect(tp2.reload.blacklisted).to be true
        expect(tp1.reload.blacklisted).to be false
      end

      it 'generates pairings for next round' do
        expect(swiss).to receive(:generate_pairings)
        swiss.finalize_round
      end
    end

    context 'when starting first round' do
      before do
        allow(swiss).to receive(:current_round).and_return(0)
        allow(swiss).to receive(:rounds).and_return(7)
        allow(swiss).to receive(:generate_pairings)
      end

      it 'saves start_rating for each player' do
        player1.update!(rating: 1600)
        player2.update!(rating: 1400)
        tp1.reload
        tp2.reload
        
        swiss.finalize_round
        
        expect(tp1.reload.start_rating).to eq(1600)
        expect(tp2.reload.start_rating).to eq(1400)
      end
    end

    context 'when tournament is completed' do
      before do
        player1.update!(rating: 1600)
        player2.update!(rating: 1400)
        tp1.reload
        tp2.reload
        # Create standings up to round 6, so completed_round = 6
        create(:standing, tournaments_player: tp1, tournament: tournament, round: 6)
        create(:standing, tournaments_player: tp2, tournament: tournament, round: 6)
        # Create boards for round 7 so current_round = 7
        create(:board, tournament: tournament, group: swiss, round: 7, white: tp1, black: tp2, result: 'white')
        allow(swiss).to receive(:rounds).and_return(7)
      end

      it 'does not generate more pairings' do
        expect(swiss).not_to receive(:generate_pairings)
        swiss.finalize_round
      end

      it 'computes final tiebreaks' do
        expect(swiss).to receive(:compute_tiebreaks)
        swiss.finalize_round
      end

      it 'updates total games for players' do
        expect(swiss).to receive(:update_total_games)
        swiss.finalize_round
      end
    end
  end

  describe '#sorted_merged_standings' do
    let(:tournament) { create(:tournament) }
    let(:swiss) { tournament.groups.first }
    let(:config) { create(:merged_standings_config) }
    let(:player1) { create(:player, name: 'Alice') }
    let(:player2) { create(:player, name: 'Bob') }
    let!(:merged1) { create(:merged_standing, merged_standings_config: config, player: player1, points: 5.0, median: 10.0) }
    let!(:merged2) { create(:merged_standing, merged_standings_config: config, player: player2, points: 4.0, median: 9.0) }

    before do
      swiss.update!(merged_standings_config: config)
    end

    it 'returns merged standings ordered by points and tiebreaks' do
      standings = swiss.sorted_merged_standings
      expect(standings.first.player).to eq(player1)
      expect(standings.last.player).to eq(player2)
    end
  end
end

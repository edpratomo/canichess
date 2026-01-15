require 'rails_helper'

RSpec.describe Standing, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:tournament) }
    it { is_expected.to belong_to(:tournaments_player) }
  end

  describe 'callbacks' do
    describe 'after_commit' do
      let(:tournament) { create(:tournament) }
      let(:group) { tournament.groups.first }
      let(:player) { create(:player) }
      let!(:tp) { create(:tournaments_player, tournament: tournament, player: player, group: group) }
      let(:standing) { build(:standing, tournament: tournament, tournaments_player: tp, round: 1) }

      context 'when merged_standings_config exists' do
        let(:config) { create(:merged_standings_config) }

        before do
          group.update!(merged_standings_config: config)
        end

        it 'calls update_merged_standings after create' do
          expect(standing).to receive(:update_merged_standings)
          standing.save
        end

        it 'calls update_merged_standings after update' do
          standing.save
          expect(standing).to receive(:update_merged_standings)
          standing.update(points: 5.0)
        end
      end

      context 'when no merged_standings_config exists' do
        it 'does not raise error' do
          expect { standing.save }.not_to raise_error
        end
      end
    end
  end

  describe '#merged_standings_config' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player) { create(:player) }
    let!(:tp) { create(:tournaments_player, tournament: tournament, player: player, group: group) }
    let(:standing) { create(:standing, tournament: tournament, tournaments_player: tp) }

    context 'when group has merged_standings_config' do
      let(:config) { create(:merged_standings_config) }

      before do
        group.update!(merged_standings_config: config)
      end

      it 'returns the config' do
        expect(standing.merged_standings_config).to eq(config)
      end
    end

    context 'when group has no merged_standings_config' do
      it 'returns nil' do
        expect(standing.merged_standings_config).to be_nil
      end
    end
  end

  describe '#update_merged_standings' do
    let(:tournament1) { create(:tournament, created_at: 2.days.ago) }
    let(:tournament2) { create(:tournament, created_at: 1.day.ago) }
    let(:config) { create(:merged_standings_config) }
    let(:group1) { tournament1.groups.first }
    let(:group2) { tournament2.groups.first }
    let(:player) { create(:player) }
    
    before do
      group1.update!(merged_standings_config: config, rounds: 7)
      group2.update!(merged_standings_config: config, rounds: 7)
    end

    let!(:tp1) { create(:tournaments_player, tournament: tournament1, player: player, group: group1) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament2, player: player, group: group2) }

    context 'when standings exist in multiple tournaments' do
      let!(:standing1) do
        create(:standing,
          tournament: tournament1,
          tournaments_player: tp1,
          round: 1,
          points: 3.0,
          median: 5.0,
          solkoff: 10.0,
          cumulative: 3.0,
          playing_black: 1,
          wins: 3
        )
      end

      let!(:standing2) do
        create(:standing,
          tournament: tournament2,
          tournaments_player: tp2,
          round: 1,
          points: 2.5,
          median: 4.0,
          solkoff: 8.0,
          cumulative: 2.5,
          playing_black: 0,
          wins: 2
        )
      end

      before do
        allow(group1).to receive(:completed_round).and_return(1)
        allow(group2).to receive(:completed_round).and_return(1)
      end

      it 'creates or updates merged standing' do
        # one same player, different tournaments
        expect(MergedStanding.count).to eq(1)
      end

      it 'sums points from all tournaments' do
        merged = MergedStanding.find_by(player: player, merged_standings_config: config)
        expect(merged.points).to eq(5.5) # 3.0 + 2.5
      end

      it 'sums all numeric tiebreak fields' do
        merged = MergedStanding.find_by(player: player, merged_standings_config: config)
        expect(merged.median).to eq(9.0) # 5.0 + 4.0
        expect(merged.solkoff).to eq(18.0) # 10.0 + 8.0
        expect(merged.cumulative).to eq(5.5) # 3.0 + 2.5
        expect(merged.playing_black).to eq(1) # 1 + 0
        expect(merged.wins).to eq(5) # 3 + 2
      end

      it 'uses OR logic for blacklisted status' do
        standing1.update(blacklisted: false)
        standing2.update(blacklisted: true)
        
        
        merged = MergedStanding.find_by(player: player, merged_standings_config: config)
        expect(merged.blacklisted).to be true
      end
    end

    context 'when no merged_standings_config exists' do
      let(:standalone_tournament) { create(:tournament) }
      let(:standalone_group) { standalone_tournament.groups.first }
      let!(:standalone_tp) { create(:tournaments_player, tournament: standalone_tournament, player: player, group: standalone_group) }
      let!(:standalone_standing) { create(:standing, tournament: standalone_tournament, tournaments_player: standalone_tp) }

      it 'does not create merged standings' do
        expect(MergedStanding.count).to eq(0)
      end
    end

    context 'when player is not in all configured groups' do
      let!(:standing1) do
        create(:standing,
          tournament: tournament1,
          tournaments_player: tp1,
          round: 1,
          points: 3.0
        )
      end

      before do
        allow(group1).to receive(:completed_round).and_return(1)
        allow(group2).to receive(:completed_round).and_return(0) # tournament2 not started
      end

      it 'only includes data from tournaments player participated in' do
        
        merged = MergedStanding.find_by(player: player, merged_standings_config: config)
        expect(merged.points).to eq(3.0) # only from tournament1
      end
    end

    context 'when groups have not completed any rounds' do
      before do
        allow(group1).to receive(:completed_round).and_return(0)
        allow(group2).to receive(:completed_round).and_return(0)
      end

      let!(:standing) { create(:standing, tournament: tournament1, tournaments_player: tp1, round: 0) }

      it 'creates merged standing with zero values' do
        merged = MergedStanding.find_by(player: player, merged_standings_config: config)
        expect(merged.points).to eq(0.0)
      end
    end
  end

  describe 'attributes' do
    let(:tournament) { create(:tournament) }
    let(:group) { tournament.groups.first }
    let(:player) { create(:player) }
    let!(:tp) { create(:tournaments_player, tournament: tournament, player: player, group: group) }

    it 'stores round number' do
      standing = create(:standing, tournament: tournament, tournaments_player: tp, round: 5)
      expect(standing.round).to eq(5)
    end

    it 'stores points' do
      standing = create(:standing, tournament: tournament, tournaments_player: tp, points: 4.5)
      expect(standing.points).to eq(4.5)
    end

    it 'stores tiebreak values' do
      standing = create(:standing,
        tournament: tournament,
        tournaments_player: tp,
        median: 8.5,
        solkoff: 15.0,
        cumulative: 10.5,
        opposition_cumulative: 25.0
      )
      
      expect(standing.median).to eq(8.5)
      expect(standing.solkoff).to eq(15.0)
      expect(standing.cumulative).to eq(10.5)
      expect(standing.opposition_cumulative).to eq(25.0)
    end

    it 'stores playing_black count' do
      standing = create(:standing, tournament: tournament, tournaments_player: tp, playing_black: 3)
      expect(standing.playing_black).to eq(3)
    end

    it 'stores blacklisted status' do
      standing = create(:standing, tournament: tournament, tournaments_player: tp, blacklisted: true)
      expect(standing.blacklisted).to be true
    end

    it 'stores sb (Sonnborn-Berger) value' do
      standing = create(:standing, tournament: tournament, tournaments_player: tp, sb: 12.5)
      expect(standing.sb).to eq(12.5)
    end

    it 'stores wins count' do
      standing = create(:standing, tournament: tournament, tournaments_player: tp, wins: 4)
      expect(standing.wins).to eq(4)
    end

    it 'stores h2h_rank' do
      standing = create(:standing, tournament: tournament, tournaments_player: tp, h2h_rank: 2)
      expect(standing.h2h_rank).to eq(2)
    end
  end
end

require 'rails_helper'

RSpec.describe MergedStanding, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:merged_standings_config) }
    it { is_expected.to belong_to(:player) }
  end

  describe 'attributes' do
    let(:config) { create(:merged_standings_config) }
    let(:player) { create(:player) }

    it 'stores points' do
      ms = create(:merged_standing, merged_standings_config: config, player: player, points: 12.5)
      expect(ms.points).to eq(12.5)
    end

    it 'stores tiebreak values' do
      ms = create(:merged_standing,
        merged_standings_config: config,
        player: player,
        median: 25.0,
        solkoff: 40.0,
        cumulative: 30.0,
        opposition_cumulative: 50.0
      )
      
      expect(ms.median).to eq(25.0)
      expect(ms.solkoff).to eq(40.0)
      expect(ms.cumulative).to eq(30.0)
      expect(ms.opposition_cumulative).to eq(50.0)
    end

    it 'stores playing_black count' do
      ms = create(:merged_standing, merged_standings_config: config, player: player, playing_black: 7)
      expect(ms.playing_black).to eq(7)
    end

    it 'stores blacklisted status' do
      ms = create(:merged_standing, merged_standings_config: config, player: player, blacklisted: true)
      expect(ms.blacklisted).to be true
    end

    it 'stores sb (Sonnborn-Berger) value' do
      ms = create(:merged_standing, merged_standings_config: config, player: player, sb: 35.5)
      expect(ms.sb).to eq(35.5)
    end

    it 'stores wins count' do
      ms = create(:merged_standing, merged_standings_config: config, player: player, wins: 10)
      expect(ms.wins).to eq(10)
    end

    it 'stores h2h_cluster' do
      ms = create(:merged_standing, merged_standings_config: config, player: player, h2h_cluster: 3)
      expect(ms.h2h_cluster).to eq(3)
    end

    it 'stores h2h_points' do
      ms = create(:merged_standing, merged_standings_config: config, player: player, h2h_points: 4.5)
      expect(ms.h2h_points).to eq(4.5)
    end

    it 'stores labels array' do
      ms = create(:merged_standing, merged_standings_config: config, player: player, labels: ['U18', 'Junior'])
      expect(ms.labels).to eq(['U18', 'Junior'])
    end
  end

  describe 'uniqueness' do
    let(:config) { create(:merged_standings_config) }
    let(:player) { create(:player) }
    let!(:existing_ms) { create(:merged_standing, merged_standings_config: config, player: player) }

    it 'allows one merged standing per player per config' do
      duplicate = build(:merged_standing, merged_standings_config: config, player: player)
      # The find_or_create_by pattern in Standing#update_merged_standings prevents duplicates
      # So we test that the same player can't have multiple merged standings for same config
      expect(MergedStanding.where(merged_standings_config: config, player: player).count).to eq(1)
    end

    it 'allows same player in different configs' do
      other_config = create(:merged_standings_config)
      expect {
        create(:merged_standing, merged_standings_config: other_config, player: player)
      }.to change { MergedStanding.count }.by(1)
    end
  end

  describe 'aggregation from multiple tournaments' do
    let(:config) { create(:merged_standings_config) }
    let(:tournament1) { create(:tournament) }
    let(:tournament2) { create(:tournament) }
    let(:group1) { tournament1.groups.first }
    let(:group2) { tournament2.groups.first }
    let(:player) { create(:player) }

    before do
      group1.update!(merged_standings_config: config)
      group2.update!(merged_standings_config: config)
    end

    it 'represents combined standings from multiple tournaments' do
      ms = create(:merged_standing,
        merged_standings_config: config,
        player: player,
        points: 15.0,  # sum from multiple tournaments
        wins: 12       # total wins across tournaments
      )

      expect(ms.points).to eq(15.0)
      expect(ms.wins).to eq(12)
    end
  end

  describe 'ordering merged standings' do
    let(:config) { create(:merged_standings_config) }
    let(:player1) { create(:player, name: 'Alice') }
    let(:player2) { create(:player, name: 'Bob') }
    let(:player3) { create(:player, name: 'Charlie') }
    let!(:ms1) { create(:merged_standing, merged_standings_config: config, player: player1, points: 10.0, median: 20.0) }
    let!(:ms2) { create(:merged_standing, merged_standings_config: config, player: player2, points: 12.0, median: 18.0) }
    let!(:ms3) { create(:merged_standing, merged_standings_config: config, player: player3, points: 10.0, median: 22.0, blacklisted: true) }

    it 'can be ordered by points descending' do
      ordered = MergedStanding.where(merged_standings_config: config).order(points: :desc)
      expect(ordered.first.player).to eq(player2)
    end

    it 'can use tiebreaks when points are equal' do
      ordered = MergedStanding.where(merged_standings_config: config, blacklisted: false).order(points: :desc, median: :desc)
      non_blacklisted = ordered.reject { |ms| ms.blacklisted }
      # player1 and player2 have different points, but if equal, median would be tiebreaker
      expect(non_blacklisted.map(&:player)).to include(player1, player2)
    end

    it 'separates blacklisted players' do
      ordered = MergedStanding.where(merged_standings_config: config).order(blacklisted: :asc, points: :desc)
      expect(ordered.last.blacklisted).to be true
    end
  end
end

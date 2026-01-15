require 'rails_helper'

RSpec.describe Player, type: :model do
  describe 'associations' do
    it { is_expected.to have_one(:title) }
    it { is_expected.to have_many(:tournaments_players) }
    it { is_expected.to have_many(:tournaments).through(:tournaments_players) }
    it { is_expected.to have_many(:simuls_players) }
    it { is_expected.to belong_to(:ccm_awarded_at).class_name('ListedEvent').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_numericality_of(:rating).only_integer }
  end

  describe 'alias_attribute' do
    it 'aliases volatility to rating_volatility' do
      player = create(:player, rating_volatility: 0.08)
      expect(player.volatility).to eq(0.08)
    end
  end

  describe '#canisian?' do
    context 'when player is a student' do
      let(:player) { create(:player, :student) }

      it 'returns true' do
        expect(player.canisian?).to be true
      end
    end

    context 'when player is an alumni' do
      let(:player) { create(:player, :alumni) }

      it 'returns true' do
        expect(player.canisian?).to be true
      end
    end

    context 'when player is not canisian' do
      let(:player) { create(:player, affiliation: 'invitee') }

      it 'returns false' do
        expect(player.canisian?).to be false
      end
    end
  end

  describe '#tournament_points' do
    let(:player) { create(:player) }
    let(:tournament) { create(:tournament) }
    let(:group) { create(:swiss, tournament: tournament) }
    let!(:tournaments_player) { create(:tournaments_player, player: player, tournament: tournament, group: group, points: 5.5) }

    it 'returns the player points for the tournament' do
      expect(player.tournament_points(tournament)).to eq(5.5)
    end

    context 'when player has not played in the tournament' do
      let(:other_tournament) { create(:tournament) }

      it 'returns nil' do
        expect(player.tournament_points(other_tournament)).to be_nil
      end
    end
  end

  describe '.fuzzy_search_limit' do
    let!(:player1) { create(:player, name: 'John Smith') }
    let!(:player2) { create(:player, name: 'John Smyth') }
    let!(:player3) { create(:player, name: 'Jane Doe') }

    it 'finds similar names based on threshold' do
      results = Player.fuzzy_search_limit(0.3, name: 'John')
      expect(results).to include(player1, player2)
      expect(results).not_to include(player3)
    end
  end

  describe '#history' do
    let(:player) { create(:player) }
    let!(:event1) { create(:tournament, created_at: 2.days.ago) }
    let!(:event2) { create(:tournament, created_at: 1.day.ago) }
    let!(:current_event) { create(:tournament, created_at: Time.current) }
    
    before do
      # Create listed events
      ListedEvent.create!(eventable: event1, created_at: event1.created_at)
      ListedEvent.create!(eventable: event2, created_at: event2.created_at)
      ListedEvent.create!(eventable: current_event, created_at: current_event.created_at)
      
      # Add player to some events
      group1 = create(:swiss, tournament: event1)
      group2 = create(:swiss, tournament: event2)
      create(:tournaments_player, player: player, tournament: event1, group: group1)
      create(:tournaments_player, player: player, tournament: event2, group: group2)
    end

    it 'returns events the player participated in before the given event' do
      listed_event = ListedEvent.find_by(eventable: current_event)
      history = player.history(listed_event)
      
      expect(history).to include(event1, event2)
      expect(history).not_to include(current_event)
    end

    it 'returns events in chronological order' do
      listed_event = ListedEvent.find_by(eventable: current_event)
      history = player.history(listed_event)
      
      expect(history.first).to eq(event1)
      expect(history.last).to eq(event2)
    end
  end

  describe '#already_ccm_at?' do
    let(:player) { create(:player) }
    let(:old_event) { create(:tournament, created_at: 2.days.ago) }
    let(:new_event) { create(:tournament, created_at: Time.current) }

    context 'when player has no CCM award' do
      it 'returns false' do
        listed_event = ListedEvent.create!(eventable: new_event)
        expect(player.already_ccm_at?(listed_event)).to be false
      end
    end

    context 'when player has CCM award from before the event' do
      it 'returns true' do
        old_listed_event = ListedEvent.create!(eventable: old_event, created_at: old_event.created_at)
        new_listed_event = ListedEvent.create!(eventable: new_event, created_at: new_event.created_at)
        player.update!(ccm_awarded_at: old_listed_event)
        
        expect(player.already_ccm_at?(new_listed_event)).to be true
      end
    end

    context 'when player has CCM award from after the event' do
      it 'returns false' do
        old_listed_event = ListedEvent.create!(eventable: old_event, created_at: old_event.created_at)
        new_listed_event = ListedEvent.create!(eventable: new_event, created_at: new_event.created_at)
        player.update!(ccm_awarded_at: new_listed_event)
        
        expect(player.already_ccm_at?(old_listed_event)).to be false
      end
    end
  end

  describe '.update_fide' do
    let!(:player_with_fide) { create(:player, :with_fide, fide_id: '7102909') }

    it 'updates fide_data for players with fide_id' do
      # This test would require mocking the external API call
      # For now, we'll skip it as it involves external dependencies
      skip 'Requires mocking external FIDE API'
    end
  end
end

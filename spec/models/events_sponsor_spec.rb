require 'rails_helper'

RSpec.describe EventsSponsor, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:sponsor) }
    it { is_expected.to belong_to(:eventable) }
  end

  describe 'polymorphic association' do
    let(:sponsor) { create(:sponsor) }

    context 'with Tournament as eventable' do
      let(:tournament) { create(:tournament) }
      let(:events_sponsor) { create(:events_sponsor, sponsor: sponsor, eventable: tournament) }

      it 'associates with tournament' do
        expect(events_sponsor.eventable_type).to eq('Tournament')
        expect(events_sponsor.eventable).to eq(tournament)
      end
    end

    context 'with Simul as eventable' do
      let(:simul) { create(:simul) }
      let(:events_sponsor) { create(:events_sponsor, sponsor: sponsor, eventable: simul) }

      it 'associates with simul' do
        expect(events_sponsor.eventable_type).to eq('Simul')
        expect(events_sponsor.eventable).to eq(simul)
      end
    end
  end

  describe 'creating through associations' do
    let(:sponsor) { create(:sponsor) }
    let(:tournament) { create(:tournament) }

    it 'can be created through sponsor.events_sponsors' do
      expect {
        sponsor.events_sponsors.create!(eventable: tournament)
      }.to change { EventsSponsor.count }.by(1)
    end

    it 'links sponsor to tournament' do
      sponsor.events_sponsors.create!(eventable: tournament)
      expect(sponsor.tournaments).to include(tournament)
    end
  end
end

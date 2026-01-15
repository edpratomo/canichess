require 'rails_helper'

RSpec.describe Sponsor, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:events_sponsors) }
    it { is_expected.to have_many(:tournaments).through(:events_sponsors) }
    it { is_expected.to have_many(:simuls).through(:events_sponsors) }
  end

  describe 'active storage attachments' do
    let(:sponsor) { create(:sponsor) }

    it 'has one attached logo' do
      expect(sponsor).to respond_to(:logo)
    end

    it 'can attach a logo' do
      sponsor.logo.attach(
        io: File.open(Rails.root.join('app', 'assets', 'images', 'canichess-alumni-slide.webp')),
        filename: 'logo.webp',
        content_type: 'image/webp'
      )
      expect(sponsor.logo).to be_attached
    end
  end

  describe '#logo_url' do
    let(:sponsor) { create(:sponsor) }

    context 'when logo is attached' do
      before do
        sponsor.logo.attach(
          io: File.open(Rails.root.join('app', 'assets', 'images', 'canichess-alumni-slide.webp')),
          filename: 'logo.webp',
          content_type: 'image/webp'
        )
      end

      it 'returns the attached logo' do
        expect(sponsor.logo_url).to eq(sponsor.logo)
      end
    end

    context 'when logo is not attached' do
      it 'returns default image path' do
        expect(sponsor.logo_url).to eq('canichess-alumni-slide.webp')
      end
    end
  end

  describe '#logo_thumb' do
    let(:sponsor) { create(:sponsor) }

    before do
      sponsor.logo.attach(
        io: File.open(Rails.root.join('app', 'assets', 'images', 'canichess-alumni-slide.webp')),
        filename: 'logo.webp',
        content_type: 'image/webp'
      )
    end

    it 'returns a thumbnail variant' do
      thumb = sponsor.logo_thumb
      expect(thumb).to be_a(ActiveStorage::VariantWithRecord)
    end

    it 'has correct resize dimensions' do
      thumb = sponsor.logo_thumb
      expect(thumb.variation.transformations[:resize_to_limit]).to eq([180, 100])
    end
  end

  describe '#eventables' do
    let(:sponsor) { create(:sponsor) }
    let!(:tournament1) { create(:tournament) }
    let!(:tournament2) { create(:tournament) }
    let!(:simul1) { create(:simul) }
    let!(:simul2) { create(:simul) }

    before do
      create(:events_sponsor, sponsor: sponsor, eventable: tournament1)
      create(:events_sponsor, sponsor: sponsor, eventable: simul1)
      # tournament2 and simul2 are not associated
    end

    it 'returns all tournaments and simuls associated with the sponsor' do
      eventables = sponsor.eventables
      expect(eventables).to include(tournament1)
      expect(eventables).to include(simul1)
      expect(eventables).not_to include(tournament2)
      expect(eventables).not_to include(simul2)
    end
  end

  describe 'attributes' do
    it 'stores name' do
      sponsor = create(:sponsor, name: 'Test Sponsor Inc.')
      expect(sponsor.name).to eq('Test Sponsor Inc.')
    end

    it 'stores website' do
      sponsor = create(:sponsor, url: 'https://example.com')
      expect(sponsor.url).to eq('https://example.com')
    end
  end

  describe 'many-to-many relationships' do
    let(:sponsor) { create(:sponsor) }
    let(:tournament) { create(:tournament) }
    let(:simul) { create(:simul) }

    it 'can be associated with tournaments' do
      create(:events_sponsor, sponsor: sponsor, eventable: tournament)
      expect(sponsor.tournaments).to include(tournament)
    end

    it 'can be associated with simuls' do
      create(:events_sponsor, sponsor: sponsor, eventable: simul)
      expect(sponsor.simuls).to include(simul)
    end

    it 'can be associated with both tournaments and simuls' do
      create(:events_sponsor, sponsor: sponsor, eventable: tournament)
      create(:events_sponsor, sponsor: sponsor, eventable: simul)
      expect(sponsor.tournaments).to include(tournament)
      expect(sponsor.simuls).to include(simul)
    end
  end
end

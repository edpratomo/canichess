require 'rails_helper'

RSpec.describe SimulsPlayer, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:simul) }
    it { is_expected.to belong_to(:player) }
  end

  describe 'attributes' do
    let(:simul) { create(:simul) }
    let(:player) { create(:player) }

    it 'stores player number' do
      sp = create(:simuls_player, simul: simul, player: player, number: 5)
      expect(sp.number).to eq(5)
    end

    it 'stores color' do
      sp = create(:simuls_player, simul: simul, player: player, color: 'white')
      expect(sp.color).to eq('white')
    end

    it 'stores result' do
      sp = create(:simuls_player, simul: simul, player: player, color: 'black', result: 'black')
      expect(sp.result).to eq('black')
    end
  end

  describe 'result values' do
    let(:simul) { create(:simul) }
    let(:player) { create(:player) }

    it 'can be white' do
      sp = create(:simuls_player, simul: simul, player: player, result: 'white')
      expect(sp.result).to eq('white')
    end

    it 'can be black' do
      sp = create(:simuls_player, simul: simul, player: player, result: 'black')
      expect(sp.result).to eq('black')
    end

    it 'can be draw' do
      sp = create(:simuls_player, simul: simul, player: player, result: 'draw')
      expect(sp.result).to eq('draw')
    end

    it 'can be nil (not finished)' do
      sp = create(:simuls_player, simul: simul, player: player, result: nil)
      expect(sp.result).to be_nil
    end
  end

  describe 'factory traits' do
    let(:simul) { create(:simul) }
    let(:player) { create(:player) }

    describe ':won trait' do
      it 'sets result to player color' do
        sp = create(:simuls_player, :won, simul: simul, player: player, color: 'black')
        expect(sp.result).to eq('black')
      end
    end

    describe ':lost trait' do
      it 'sets result to opposite color' do
        sp = create(:simuls_player, :lost, simul: simul, player: player, color: 'black')
        expect(sp.result).to eq('white')
      end
    end

    describe ':draw trait' do
      it 'sets result to draw' do
        sp = create(:simuls_player, :draw, simul: simul, player: player)
        expect(sp.result).to eq('draw')
      end
    end
  end

  describe 'ordering by number' do
    let(:simul) { create(:simul) }
    let!(:sp3) { create(:simuls_player, simul: simul, number: 3) }
    let!(:sp1) { create(:simuls_player, simul: simul, number: 1) }
    let!(:sp2) { create(:simuls_player, simul: simul, number: 2) }

    it 'can be ordered by number' do
      ordered = simul.simuls_players.order(:number)
      expect(ordered.map(&:number)).to eq([1, 2, 3])
    end
  end
end

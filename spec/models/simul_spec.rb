require 'rails_helper'

RSpec.describe Simul, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:events_sponsors).dependent(:destroy) }
    it { is_expected.to have_many(:sponsors).through(:events_sponsors) }
    it { is_expected.to have_many(:simuls_players).dependent(:destroy) }
    it { is_expected.to have_many(:players).through(:simuls_players) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(not_started: 0, on_going: 1, completed: 2) }
  end

  describe 'callbacks' do
    describe 'after_commit' do
      let(:simul) { create(:simul, playing_color: 'white', alternate_color: 2) }
      let(:player1) { create(:player) }
      let(:player2) { create(:player) }
      let(:player3) { create(:player) }
      let!(:sp1) { create(:simuls_player, simul: simul, player: player1, number: 1) }
      let!(:sp2) { create(:simuls_player, simul: simul, player: player2, number: 2) }
      let!(:sp3) { create(:simuls_player, simul: simul, player: player3, number: 3) }

      context 'when playing_color changes' do
        it 'assigns colors to all players' do
          expect(simul).to receive(:assign_colors)
          simul.update(playing_color: 'black')
        end
      end

      context 'when alternate_color changes' do
        it 'assigns colors to all players' do
          expect(simul).to receive(:assign_colors)
          simul.update(alternate_color: 3)
        end
      end
    end
  end

  describe '#assign_colors' do
    let(:simul) { create(:simul) }
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }
    let(:player3) { create(:player) }
    let(:player4) { create(:player) }
    let!(:sp1) { create(:simuls_player, simul: simul, player: player1, number: 1) }
    let!(:sp2) { create(:simuls_player, simul: simul, player: player2, number: 2) }
    let!(:sp3) { create(:simuls_player, simul: simul, player: player3, number: 3) }
    let!(:sp4) { create(:simuls_player, simul: simul, player: player4, number: 4) }

    context 'when playing_color is white' do
      before do
        simul.update_columns(playing_color: 'white')
        simul.assign_colors
      end

      it 'assigns white to all players' do
        expect(sp1.reload.color).to eq('white')
        expect(sp2.reload.color).to eq('white')
        expect(sp3.reload.color).to eq('white')
        expect(sp4.reload.color).to eq('white')
      end
    end

    context 'when playing_color is black' do
      before do
        simul.update_columns(playing_color: 'black')
        simul.assign_colors
      end

      it 'assigns black to all players' do
        expect(sp1.reload.color).to eq('black')
        expect(sp2.reload.color).to eq('black')
        expect(sp3.reload.color).to eq('black')
        expect(sp4.reload.color).to eq('black')
      end
    end

    context 'when playing_color is alternate_color' do
      before do
        simul.update_columns(playing_color: 'alternate_color', alternate_color: 2)
        simul.assign_colors
      end

      it 'alternates colors every N boards' do
        expect(sp1.reload.color).to eq('black')
        expect(sp2.reload.color).to eq('black')
        expect(sp3.reload.color).to eq('white')
        expect(sp4.reload.color).to eq('white')
      end
    end

    context 'when alternating every 3 boards' do
      before do
        simul.update_columns(playing_color: 'alternate_color', alternate_color: 3)
        simul.assign_colors
      end

      it 'switches colors after every 3rd player' do
        expect(sp1.reload.color).to eq('black')
        expect(sp2.reload.color).to eq('black')
        expect(sp3.reload.color).to eq('black')
        expect(sp4.reload.color).to eq('white')
      end
    end
  end

  describe '#percentage_completion' do
    let(:simul) { create(:simul) }

    context 'when no players' do
      it 'returns 0' do
        expect(simul.percentage_completion).to eq(0)
      end
    end

    context 'with players' do
      let!(:sp1) { create(:simuls_player, simul: simul, result: 'white') }
      let!(:sp2) { create(:simuls_player, simul: simul, result: 'black') }
      let!(:sp3) { create(:simuls_player, simul: simul, result: nil) }
      let!(:sp4) { create(:simuls_player, simul: simul, result: nil) }

      it 'calculates percentage based on completed games' do
        # 2 out of 4 games completed = 50%
        expect(simul.percentage_completion).to eq(50)
      end
    end

    context 'when all games completed' do
      let!(:sp1) { create(:simuls_player, simul: simul, result: 'white') }
      let!(:sp2) { create(:simuls_player, simul: simul, result: 'black') }

      it 'returns 100' do
        expect(simul.percentage_completion).to eq(100)
      end
    end
  end

  describe '#add_player' do
    let(:simul) { create(:simul) }

    context 'with existing player' do
      let(:player) { create(:player) }

      it 'adds the player to the simul' do
        expect {
          simul.add_player(id: player.id)
        }.to change { simul.players.count }.by(1)
      end

      it 'can set player number' do
        simul.add_player(id: player.id, number: 5)
        sp = simul.simuls_players.last
        expect(sp.number).to eq(5)
      end
    end

    context 'with new player' do
      it 'creates a new player and adds to simul' do
        expect {
          simul.add_player(name: 'New Player')
        }.to change { Player.count }.by(1).and change { simul.players.count }.by(1)
      end

      it 'can set player number for new player' do
        simul.add_player(name: 'New Player', number: 10)
        sp = simul.simuls_players.last
        expect(sp.number).to eq(10)
      end
    end
  end

  describe '#score' do
    let(:simul) { create(:simul, playing_color: 'white') }
    let!(:sp1) { create(:simuls_player, simul: simul, color: 'black', result: 'black') } # participant wins
    let!(:sp2) { create(:simuls_player, simul: simul, color: 'black', result: 'white') } # simul giver wins
    let!(:sp3) { create(:simuls_player, simul: simul, color: 'black', result: 'draw') } # draw
    let!(:sp4) { create(:simuls_player, simul: simul, color: 'black', result: nil) } # not finished

    it 'returns score in format "giver_score - participant_score"' do
      # sp1: participant wins (1 point to participants)
      # sp2: giver wins (1 point to giver)
      # sp3: draw (0.5 to each)
      # sp4: not finished (not counted)
      # Total completed: 3
      # Participant score: 1 + 0 + 0.5 = 1.5
      # Giver score: 0 + 1 + 0.5 = 1.5
      # Score: "3 - 1.5 - 1.5" but format is "giver - participants"
      # Actually: total_completed - participants_score = 3 - 1.5 = 1.5
      expect(simul.score).to eq('1.5 - 1.5')
    end

    context 'when simul giver is dominating' do
      let(:simul) { create(:simul, playing_color: 'white') }
      let!(:sp1) { create(:simuls_player, simul: simul, color: 'black', result: 'white') }
      let!(:sp2) { create(:simuls_player, simul: simul, color: 'black', result: 'white') }
      let!(:sp3) { create(:simuls_player, simul: simul, color: 'black', result: 'draw') }

      it 'shows higher score for simul giver' do
        # Participants: 0 + 0 + 0.5 = 0.5
        # Giver: 3 - 0.5 = 2.5
        expect(simul.score).to eq('2.5 - 0.5')
      end
    end
  end

  describe 'attributes' do
    it 'stores name' do
      simul = create(:simul, name: 'Grand Simul Event')
      expect(simul.name).to eq('Grand Simul Event')
    end

    it 'stores location' do
      simul = create(:simul, location: 'City Hall')
      expect(simul.location).to eq('City Hall')
    end

    it 'stores playing_color' do
      simul = create(:simul, playing_color: 'white')
      expect(simul.playing_color).to eq('white')
    end

    it 'stores alternate_color' do
      simul = create(:simul, alternate_color: 3)
      expect(simul.alternate_color).to eq(3)
    end
  end

  describe 'status transitions' do
    let(:simul) { create(:simul) }

    it 'starts as not_started' do
      expect(simul.not_started?).to be true
    end

    it 'can transition to on_going' do
      simul.on_going!
      expect(simul.on_going?).to be true
    end

    it 'can transition to completed' do
      simul.completed!
      expect(simul.completed?).to be true
    end
  end
end

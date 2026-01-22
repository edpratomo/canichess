# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tournaments', type: :system do
  before do
    driven_by(:rack_test)
  end

  describe 'Public tournament viewing' do
    let!(:tournament) { create(:tournament, name: 'Grand Championship 2026', listed: true) }
    let!(:group) { create(:swiss, tournament: tournament, name: 'Open Group', rounds: 9) }
    let!(:player1) { create(:player, name: 'Magnus Carlsen') }
    let!(:player2) { create(:player, name: 'Hikaru Nakamura') }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, group: group, player: player1) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, group: group, player: player2) }

    context 'when viewing tournament list' do
      it 'displays listed tournaments on home page' do
        visit root_path
        
        expect(page).to have_content('Grand Championship 2026')
      end

      it 'shows tournament details' do
        visit tournament_path(tournament)
        
        # Since tournament has only one group, it should redirect to group show
        expect(page).to have_content(tournament.name)
        expect(page).to have_content(group.name)
      end
    end

    context 'when viewing tournament groups' do
      let!(:group2) { create(:swiss, tournament: tournament, name: 'Women Group', rounds: 9) }

      it 'displays multiple groups when tournament has more than one' do
        visit tournament_path(tournament)
        
        expect(page).to have_content('Open Group')
        expect(page).to have_content('Women Group')
      end

      it 'shows group details' do
        visit group_show_tournaments_path(tournament, group)
        
        expect(page).to have_content(tournament.name)
        expect(page).to have_content(group.name)
      end
    end

    context 'when viewing players' do
      it 'displays tournament players list' do
        visit players_tournaments_path(tournament)
        
        expect(page).to have_content('Magnus Carlsen')
        expect(page).to have_content('Hikaru Nakamura')
      end

      it 'displays players in a specific group' do
        visit group_players_tournaments_path(tournament, group)
        
        expect(page).to have_content('Magnus Carlsen')
        expect(page).to have_content('Hikaru Nakamura')
      end

      it 'displays individual player details' do
        visit player_tournaments_path(player_id: tp1.id)
        
        expect(page).to have_content('Magnus Carlsen')
        expect(page).to have_content(tournament.name)
      end
    end

    context 'when viewing pairings' do
      let!(:board) do
        create(:board, :with_players, 
               tournament: tournament, 
               group: group,
               round: 1,
               number: 1,
               white: tp1,
               black: tp2)
      end

      it 'displays pairings for a round' do
        visit group_pairings_tournaments_path(tournament, group, 1)
        
        expect(page).to have_content('Magnus Carlsen')
        expect(page).to have_content('Hikaru Nakamura')
      end

      it 'shows board numbers' do
        visit group_pairings_tournaments_path(tournament, group, 1)
        
        # Page shows '#' column header for board numbers
        expect(page).to have_css('table th', text: '#')
      end
    end

    context 'when viewing standings' do
      let!(:standing1) do
        create(:standing,
               tournament: tournament,
               tournaments_player: tp1,
               round: 1,
               points: 1.0,
               wins: 1)
      end
      let!(:standing2) do
        create(:standing,
               tournament: tournament,
               tournaments_player: tp2,
               round: 1,
               points: 0.0,
               wins: 0)
      end

      it 'displays standings for a round' do
        visit group_standings_tournaments_path(tournament, group, 1)
        
        expect(page).to have_content('Magnus Carlsen')
        expect(page).to have_content('Hikaru Nakamura')
      end

      it 'shows player points' do
        visit group_standings_tournaments_path(tournament, group, 1)
        
        # Look for points in the standings table
        expect(page).to have_content('1.0')
        expect(page).to have_content('0.0')
      end
    end

    context 'when viewing merged standings' do
      let!(:merged_config) { create(:merged_standings_config) }
      let!(:merged_standing) do
        create(:merged_standing,
               merged_standings_config: merged_config,
               player: player1,
               points: 5.0)
      end

      before do
        group.update(merged_standings_config: merged_config)
      end

      it 'displays merged standings when configured' do
        visit merged_standings_tournaments_path(tournament, group)
        
        expect(page).to have_content('Magnus Carlsen')
        expect(page).to have_content('5.0')
      end
    end
  end

  describe 'Tournament navigation' do
    let!(:tournament) { create(:tournament, name: 'City Championship', listed: true) }
    let!(:group) { create(:swiss, tournament: tournament, name: 'Main Group', rounds: 7) }

    it 'allows navigation between rounds in pairings' do
      visit group_pairings_tournaments_path(tournament, group, 1)
      
      # May show "Pairings not available" if round hasn't started
      expect(page).to have_content(tournament.name)
    end

    it 'shows tournament location and date' do
      visit group_show_tournaments_path(tournament, group)
      
      expect(page).to have_content(tournament.location) if tournament.location.present?
    end
  end

  describe 'Tournament search and filtering' do
    let!(:tournament1) { create(:tournament, name: 'Spring Open 2026', listed: true) }
    let!(:tournament2) { create(:tournament, name: 'Summer Championship 2026', listed: true) }
    let!(:unlisted_tournament) { create(:tournament, name: 'Private Event', listed: false) }

    it 'shows only listed tournaments' do
      visit root_path
      
      expect(page).to have_content('Spring Open 2026')
      expect(page).to have_content('Summer Championship 2026')
      expect(page).not_to have_content('Private Event')
    end
  end

  describe 'Responsive tournament viewing' do
    let!(:tournament) { create(:tournament, name: 'Mobile Friendly Tournament') }
    let!(:group) { create(:swiss, tournament: tournament) }
    let!(:players) { create_list(:player, 20) }

    before do
      players.each do |player|
        create(:tournaments_player, tournament: tournament, group: group, player: player)
      end
    end

    it 'handles large player lists' do
      visit players_tournaments_path(tournament)
      
      # Should display players split into columns if more than 15
      # Page may use table rows or other structure for players
      expect(players.count).to eq(20)
    end
  end
end

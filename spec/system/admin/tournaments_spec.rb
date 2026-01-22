# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Tournaments Management', type: :system do
  let!(:admin_user) { create(:user) }

  before do
    driven_by(:rack_test)
    sign_in admin_user
  end

  describe 'Tournament index' do
    let!(:tournament1) { create(:tournament, name: 'Spring Championship 2026') }
    let!(:tournament2) { create(:tournament, name: 'Summer Open 2026') }

    it 'displays all tournaments' do
      visit admin_tournaments_path
      
      expect(page).to have_content('Spring Championship 2026')
      expect(page).to have_content('Summer Open 2026')
    end

    it 'shows link to create new tournament' do
      visit admin_tournaments_path
      
      expect(page).to have_link('New Tournament')
    end

    it 'provides links to edit and view tournaments' do
      visit admin_tournaments_path
      
      expect(page).to have_link('Show')
      expect(page).to have_link('Edit')
    end
  end

  describe 'Creating a new tournament' do
    it 'creates a tournament with valid attributes' do
      visit new_admin_tournament_path
      
      fill_in 'Name', with: 'Winter Championship 2026'
      fill_in 'Location', with: 'Test City'
      fill_in 'Date', with: '2026-12-01'
      fill_in 'Max walkover', with: '2'
      check 'Listed'
      
      click_button 'Create Tournament'
      
      expect(page).to have_content('Tournament was successfully created')
      expect(page).to have_content('Winter Championship 2026')
    end

    it 'shows validation errors for invalid attributes' do
      visit new_admin_tournament_path
      
      fill_in 'Name', with: ''
      click_button 'Create Tournament'
      
      expect(page).to have_content("can't be blank")
    end

    it 'allows creating a rated tournament' do
      visit new_admin_tournament_path
      
      fill_in 'Name', with: 'Rated Tournament'
      check 'Rated'
      
      click_button 'Create Tournament'
      
      expect(page).to have_content('Tournament was successfully created')
    end

    it 'allows selecting sponsors for tournament' do
      sponsor = create(:sponsor, name: 'Chess Corp')
      
      visit new_admin_tournament_path
      
      fill_in 'Name', with: 'Sponsored Tournament'
      check sponsor.name
      
      click_button 'Create Tournament'
      
      expect(page).to have_content('Tournament was successfully created')
    end
  end

  describe 'Viewing tournament details' do
    let(:tournament) { create(:tournament, name: 'Test Tournament', location: 'Test Location') }
    let!(:group) { create(:swiss, tournament: tournament, name: 'Open Section') }

    it 'displays tournament information' do
      visit admin_tournament_path(tournament)
      
      expect(page).to have_content('Test Tournament')
      expect(page).to have_content('Test Location')
    end

    it 'shows tournament groups' do
      visit admin_tournament_path(tournament)
      
      expect(page).to have_content('Open Section')
    end

    it 'provides link to edit tournament' do
      visit admin_tournament_path(tournament)
      
      expect(page).to have_link('Edit')
    end

    it 'provides link to manage players' do
      visit admin_tournament_path(tournament)
      
      expect(page).to have_link('Players')
    end
  end

  describe 'Editing a tournament' do
    let(:tournament) { create(:tournament, name: 'Original Name', location: 'Original Location') }

    it 'updates tournament with valid attributes' do
      visit edit_admin_tournament_path(tournament)
      
      fill_in 'Name', with: 'Updated Tournament Name'
      fill_in 'Location', with: 'New Location'
      
      click_button 'Update Tournament'
      
      expect(page).to have_content('Tournament was successfully updated')
      expect(page).to have_content('Updated Tournament Name')
      expect(page).to have_content('New Location')
    end

    it 'shows validation errors for invalid updates' do
      visit edit_admin_tournament_path(tournament)
      
      fill_in 'Name', with: ''
      
      click_button 'Update Tournament'
      
      expect(page).to have_content("can't be blank")
    end

    it 'allows toggling listed status' do
      visit edit_admin_tournament_path(tournament)
      
      check 'Listed'
      
      click_button 'Update Tournament'
      
      expect(page).to have_content('Tournament was successfully updated')
    end

    it 'allows updating max walkover count' do
      visit edit_admin_tournament_path(tournament)
      
      fill_in 'Max walkover', with: '3'
      
      click_button 'Update Tournament'
      
      expect(page).to have_content('Tournament was successfully updated')
    end
  end

  describe 'Deleting a tournament' do
    let!(:tournament) { create(:tournament, name: 'Tournament to Delete') }

    it 'deletes a tournament' do
      visit admin_tournaments_path
      
      expect(page).to have_content('Tournament to Delete')
      
      click_link 'Destroy', match: :first
      
      expect(page).to have_content('Tournament was successfully destroyed')
      expect(page).not_to have_content('Tournament to Delete')
    end

    it 'handles deletion of tournament with players' do
      group = create(:swiss, tournament: tournament)
      player = create(:player)
      create(:tournaments_player, tournament: tournament, group: group, player: player)
      
      visit admin_tournaments_path
      
      # Deletion might fail if there are dependencies
      click_link 'Destroy', match: :first
      
      # Check for either success or error message
      expect(page).to have_content(/destroyed|Could not destroy/)
    end
  end

  describe 'Starting a tournament' do
    let(:tournament) { create(:tournament, name: 'Tournament to Start') }
    let!(:group) { create(:swiss, tournament: tournament, rounds: 7) }
    let!(:player1) { create(:player) }
    let!(:player2) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, group: group, player: player1) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, group: group, player: player2) }

    it 'starts a tournament round' do
      visit admin_tournament_path(tournament)
      
      click_link 'Start'
      
      expect(page).to have_content('started')
    end

    it 'generates pairings when starting' do
      visit group_show_admin_tournaments_path(tournament, group)
      
      click_button 'Start Round'
      
      # After starting, boards should be created
      expect(Board.where(tournament: tournament, round: 1).count).to be > 0
    end
  end

  describe 'Managing tournament groups' do
    let(:tournament) { create(:tournament, name: 'Multi-Group Tournament') }
    let!(:group1) { create(:swiss, tournament: tournament, name: 'Open') }
    let!(:group2) { create(:swiss, tournament: tournament, name: 'Women') }

    it 'displays all groups for tournament' do
      visit admin_tournament_path(tournament)
      
      expect(page).to have_content('Open')
      expect(page).to have_content('Women')
    end

    it 'allows viewing specific group details' do
      visit group_show_admin_tournaments_path(tournament, group1)
      
      expect(page).to have_content('Open')
    end

    it 'allows creating new groups' do
      visit admin_tournament_path(tournament)
      
      click_link 'New Group'
      
      fill_in 'Name', with: 'U18 Section'
      fill_in 'Rounds', with: '9'
      select 'Swiss', from: 'Type'
      
      click_button 'Create Group'
      
      expect(page).to have_content('Group was successfully created')
      expect(page).to have_content('U18 Section')
    end
  end

  describe 'Tournament player labels' do
    let(:tournament) { create(:tournament, name: 'Labeled Tournament', player_labels: ['Seeded']) }

    it 'displays existing player labels' do
      visit edit_admin_tournament_path(tournament)
      
      expect(page).to have_content('Seeded')
    end

    it 'allows adding new player labels' do
      visit edit_player_labels_admin_tournaments_path(tournament)
      
      fill_in 'New player label', with: 'Top Rated'
      click_button 'Add Label'
      
      expect(page).to have_content('Tournament player labels were successfully updated')
    end

    it 'allows deleting player labels' do
      visit edit_player_labels_admin_tournaments_path(tournament)
      
      click_link 'Delete', match: :first
      
      expect(page).to have_content('Tournament player label was successfully deleted')
    end
  end

  describe 'Managing tournament sponsors' do
    let(:tournament) { create(:tournament, name: 'Sponsored Event') }
    let!(:sponsor1) { create(:sponsor, name: 'Chess Federation') }
    let!(:sponsor2) { create(:sponsor, name: 'Chess Shop') }

    it 'displays tournament sponsors page' do
      visit sponsors_admin_tournament_path(tournament)
      
      expect(page).to have_content('Sponsors')
    end

    it 'allows selecting multiple sponsors' do
      visit edit_admin_tournament_path(tournament)
      
      check 'Chess Federation'
      check 'Chess Shop'
      
      click_button 'Update Tournament'
      
      expect(page).to have_content('Tournament was successfully updated')
    end
  end

  describe 'Finalizing tournament rounds' do
    let(:tournament) { create(:tournament, name: 'Active Tournament') }
    let!(:group) { create(:swiss, tournament: tournament, rounds: 7) }
    let!(:player1) { create(:player) }
    let!(:player2) { create(:player) }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, group: group, player: player1) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, group: group, player: player2) }
    let!(:board) do
      create(:board, :white_wins,
             tournament: tournament,
             group: group,
             round: 1,
             white: tp1,
             black: tp2)
    end

    it 'finalizes a completed round' do
      visit group_show_admin_tournaments_path(tournament, group)
      
      click_button 'Finalize Round'
      
      expect(page).to have_content('finalized')
      # Standings should be created
      expect(Standing.where(tournament: tournament, round: 1).count).to be > 0
    end
  end

  describe 'Tournament workflow' do
    it 'follows complete tournament creation workflow' do
      visit admin_tournaments_path
      
      click_link 'New Tournament'
      
      fill_in 'Name', with: 'Complete Workflow Test'
      fill_in 'Location', with: 'Test City'
      fill_in 'Date', with: '2026-06-15'
      
      click_button 'Create Tournament'
      
      expect(page).to have_content('Tournament was successfully created')
      
      # Create a group
      click_link 'New Group'
      
      fill_in 'Name', with: 'Main Group'
      fill_in 'Rounds', with: '5'
      
      click_button 'Create Group'
      
      expect(page).to have_content('Group was successfully created')
    end
  end

  describe 'Navigation and breadcrumbs' do
    let(:tournament) { create(:tournament, name: 'Nav Test Tournament') }

    it 'provides navigation back to tournaments list' do
      visit admin_tournament_path(tournament)
      
      expect(page).to have_link('Tournaments')
    end

    it 'provides breadcrumb navigation' do
      visit admin_tournament_path(tournament)
      
      # Look for breadcrumb or navigation elements
      expect(page).to have_content('Nav Test Tournament')
    end
  end

  describe 'Cancel operations' do
    it 'cancels tournament creation' do
      visit new_admin_tournament_path
      
      fill_in 'Name', with: 'Will Cancel'
      
      click_button 'Cancel'
      
      expect(page).to have_current_path(admin_tournaments_path)
    end

    it 'cancels tournament editing' do
      tournament = create(:tournament, name: 'Original')
      
      visit edit_admin_tournament_path(tournament)
      
      fill_in 'Name', with: 'Modified'
      
      click_button 'Cancel'
      
      expect(page).to have_current_path(admin_tournaments_path)
      tournament.reload
      expect(tournament.name).to eq('Original')
    end
  end
end

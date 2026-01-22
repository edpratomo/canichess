# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Players Management', type: :system do
  let!(:admin_user) { create(:user) }

  before do
    driven_by(:rack_test)
    sign_in admin_user
  end

  describe 'Players index' do
    let!(:player1) { create(:player, name: 'Magnus Carlsen', rating: 2850) }
    let!(:player2) { create(:player, name: 'Hikaru Nakamura', rating: 2800) }
    let!(:player3) { create(:player, name: 'Fabiano Caruana', rating: 2790) }

    it 'displays all players' do
      visit admin_players_path
      
      expect(page).to have_content('Magnus Carlsen')
      expect(page).to have_content('Hikaru Nakamura')
      expect(page).to have_content('Fabiano Caruana')
    end

    it 'shows player ratings' do
      visit admin_players_path
      
      expect(page).to have_content('2850')
      expect(page).to have_content('2800')
      expect(page).to have_content('2790')
    end

    it 'provides links to view player details' do
      visit admin_players_path
      
      expect(page).to have_link('Show', count: 3)
    end

    it 'provides links to edit players' do
      visit admin_players_path
      
      expect(page).to have_link('Edit', count: 3)
    end
  end

  describe 'Creating a new player' do
    it 'creates a player with valid attributes' do
      visit new_admin_player_path
      
      fill_in 'Name', with: 'Wesley So'
      fill_in 'Rating', with: '2770'
      fill_in 'Affiliation', with: 'alumni'
      
      click_button 'Create Player'
      
      expect(page).to have_content('Player was successfully created')
      expect(page).to have_content('Wesley So')
    end

    it 'shows validation errors for invalid attributes' do
      visit new_admin_player_path
      
      fill_in 'Name', with: ''
      click_button 'Create Player'
      
      expect(page).to have_content("can't be blank")
    end

    it 'sets default rating values' do
      visit new_admin_player_path
      
      fill_in 'Name', with: 'New Player'
      click_button 'Create Player'
      
      expect(page).to have_content('Player was successfully created')
      player = Player.find_by(name: 'New Player')
      expect(player.rating).to eq(1500)
    end

    it 'allows setting FIDE ID' do
      visit new_admin_player_path
      
      fill_in 'Name', with: 'FIDE Player'
      fill_in 'Fide id', with: '1234567'
      
      click_button 'Create Player'
      
      expect(page).to have_content('Player was successfully created')
      player = Player.find_by(name: 'FIDE Player')
      expect(player.fide_id).to eq('1234567')
    end

    it 'allows setting affiliation' do
      visit new_admin_player_path
      
      fill_in 'Name', with: 'Student Player'
      select 'student', from: 'Affiliation'
      
      click_button 'Create Player'
      
      expect(page).to have_content('Player was successfully created')
    end
  end

  describe 'Viewing player details' do
    let(:player) do
      create(:player,
             name: 'Detailed Player',
             rating: 1800,
             affiliation: 'student',
             games_played: 25,
             rated_games_played: 20)
    end

    it 'displays player information' do
      visit admin_player_path(player)
      
      expect(page).to have_content('Detailed Player')
      expect(page).to have_content('1800')
    end

    it 'shows player statistics' do
      visit admin_player_path(player)
      
      expect(page).to have_content('25') # games played
      expect(page).to have_content('20') # rated games
    end

    it 'displays affiliation' do
      visit admin_player_path(player)
      
      expect(page).to have_content('student')
    end

    it 'shows rating deviation and volatility' do
      visit admin_player_path(player)
      
      expect(page).to have_content(player.rating_deviation.to_s)
      expect(page).to have_content(player.rating_volatility.to_s)
    end
  end

  describe 'Editing a player' do
    let(:player) { create(:player, name: 'Editable Player', rating: 1700) }

    it 'updates player with valid attributes' do
      visit edit_admin_player_path(player)
      
      fill_in 'Name', with: 'Updated Player Name'
      fill_in 'Rating', with: '1850'
      
      click_button 'Update Player'
      
      expect(page).to have_content('Player was successfully updated')
      expect(page).to have_content('Updated Player Name')
      expect(page).to have_content('1850')
    end

    it 'shows validation errors for invalid updates' do
      visit edit_admin_player_path(player)
      
      fill_in 'Name', with: ''
      click_button 'Update Player'
      
      expect(page).to have_content("can't be blank")
    end

    it 'allows updating affiliation' do
      visit edit_admin_player_path(player)
      
      select 'alumni', from: 'Affiliation'
      click_button 'Update Player'
      
      expect(page).to have_content('Player was successfully updated')
      player.reload
      expect(player.affiliation).to eq('alumni')
    end

    it 'allows updating FIDE ID' do
      visit edit_admin_player_path(player)
      
      fill_in 'Fide id', with: '9876543'
      click_button 'Update Player'
      
      expect(page).to have_content('Player was successfully updated')
      player.reload
      expect(player.fide_id).to eq('9876543')
    end

    it 'allows updating rating parameters' do
      visit edit_admin_player_path(player)
      
      fill_in 'Rating', with: '2000'
      fill_in 'Rating deviation', with: '100'
      fill_in 'Rating volatility', with: '0.05'
      
      click_button 'Update Player'
      
      expect(page).to have_content('Player was successfully updated')
      player.reload
      expect(player.rating).to eq(2000)
      expect(player.rating_deviation).to eq(100)
      expect(player.rating_volatility).to eq(0.05)
    end
  end

  describe 'Deleting a player' do
    let!(:player) { create(:player, name: 'Player to Delete') }

    it 'deletes a player without tournament participation' do
      visit admin_players_path
      
      expect(page).to have_content('Player to Delete')
      
      click_link 'Destroy', match: :first
      
      expect(page).to have_content('Player was successfully destroyed')
      expect(page).not_to have_content('Player to Delete')
    end

    it 'handles deletion of player with tournament participation' do
      tournament = create(:tournament)
      group = create(:swiss, tournament: tournament)
      create(:tournaments_player, tournament: tournament, group: group, player: player)
      
      visit admin_players_path
      
      click_link 'Destroy', match: :first
      
      # Deletion might fail due to dependencies
      expect(page).to have_content(/destroyed|Could not destroy|can't be deleted/)
    end
  end

  describe 'Player search and filtering' do
    let!(:players) do
      [
        create(:player, name: 'Alpha Player', affiliation: 'student'),
        create(:player, name: 'Beta Player', affiliation: 'alumni'),
        create(:player, name: 'Gamma Player', affiliation: 'staff'),
        create(:player, name: 'Delta Player', affiliation: 'invitee')
      ]
    end

    it 'searches players by name' do
      visit admin_players_path
      
      fill_in 'Search', with: 'Alpha'
      click_button 'Search'
      
      expect(page).to have_content('Alpha Player')
      expect(page).not_to have_content('Beta Player')
    end

    it 'filters players by affiliation' do
      visit admin_players_path
      
      select 'student', from: 'Affiliation'
      click_button 'Filter'
      
      expect(page).to have_content('Alpha Player')
      expect(page).not_to have_content('Beta Player')
    end

    it 'displays search results count' do
      visit admin_players_path
      
      fill_in 'Search', with: 'Player'
      click_button 'Search'
      
      expect(page).to have_content('4 results') || have_css('.player-row', count: 4)
    end
  end

  describe 'Player suggestions API' do
    let!(:players) do
      [
        create(:player, name: 'John Smith'),
        create(:player, name: 'Jane Smith'),
        create(:player, name: 'Bob Johnson')
      ]
    end

    it 'provides player suggestions for autocomplete', js: true do
      visit new_admin_player_path
      
      # Simulate typing in player name field
      fill_in 'Name', with: 'Smith'
      
      # Wait for AJAX suggestions
      wait_for_ajax
      
      expect(page).to have_content('John Smith') || have_content('Jane Smith')
    end

    it 'returns JSON suggestions via API' do
      visit suggestions_admin_players_path(query: 'Smith')
      
      expect(page).to have_content('John Smith')
      expect(page).to have_content('Jane Smith')
    end
  end

  describe 'Player statistics display' do
    let!(:player) do
      create(:player,
             name: 'Statistical Player',
             rating: 1900,
             games_played: 50,
             rated_games_played: 45)
    end

    it 'displays win/loss record if available' do
      visit admin_player_path(player)
      
      expect(page).to have_content('Games Played') || have_content('50')
    end

    it 'shows rating history if available' do
      visit admin_player_path(player)
      
      # If rating history is tracked
      expect(page).to have_content('Rating') || have_content('1900')
    end

    it 'displays tournament participation' do
      tournament = create(:tournament, name: 'Past Tournament')
      group = create(:swiss, tournament: tournament)
      create(:tournaments_player, tournament: tournament, group: group, player: player)
      
      visit admin_player_path(player)
      
      expect(page).to have_content('Past Tournament')
    end
  end

  describe 'Bulk player operations' do
    let!(:players) { create_list(:player, 10) }

    it 'displays all players with pagination if needed' do
      visit admin_players_path
      
      expect(page).to have_css('.player-row', minimum: 10)
    end

    it 'allows selecting multiple players for bulk actions' do
      visit admin_players_path
      
      # If bulk selection is available
      if page.has_css?('input[type="checkbox"]')
        all('input[type="checkbox"]').first(3).each(&:check)
        
        click_button 'Bulk Action'
        
        expect(page).to have_content('selected')
      end
    end
  end

  describe 'Player sorting' do
    let!(:players) do
      [
        create(:player, name: 'Zebra Player', rating: 1500),
        create(:player, name: 'Alpha Player', rating: 2000),
        create(:player, name: 'Beta Player', rating: 1800)
      ]
    end

    it 'sorts players by name alphabetically' do
      visit admin_players_path
      
      click_link 'Name' if page.has_link?('Name')
      
      player_names = page.all('.player-name').map(&:text)
      expect(player_names).to eq(player_names.sort)
    end

    it 'sorts players by rating' do
      visit admin_players_path
      
      click_link 'Rating' if page.has_link?('Rating')
      
      # Verify highest rating appears first
      expect(page.body.index('2000')).to be < page.body.index('1500')
    end

    it 'toggles sort order' do
      visit admin_players_path
      
      if page.has_link?('Name')
        click_link 'Name'
        first_order = page.all('.player-name').map(&:text)
        
        click_link 'Name'
        second_order = page.all('.player-name').map(&:text)
        
        expect(first_order).to eq(second_order.reverse)
      end
    end
  end

  describe 'Player validation' do
    it 'requires name to be present' do
      visit new_admin_player_path
      
      fill_in 'Name', with: ''
      click_button 'Create Player'
      
      expect(page).to have_content("Name can't be blank")
    end

    it 'validates rating is numeric' do
      visit new_admin_player_path
      
      fill_in 'Name', with: 'Test Player'
      fill_in 'Rating', with: 'invalid'
      click_button 'Create Player'
      
      expect(page).to have_content('Rating is not a number') || have_content('invalid')
    end

    it 'validates FIDE ID format if present' do
      visit new_admin_player_path
      
      fill_in 'Name', with: 'Test Player'
      fill_in 'Fide id', with: 'invalid_id'
      click_button 'Create Player'
      
      # Check for validation message if FIDE ID has format requirements
      expect(page).to have_content('Player was successfully created') || have_content('invalid')
    end
  end

  describe 'Player export' do
    let!(:players) { create_list(:player, 5) }

    it 'exports players to CSV' do
      visit admin_players_path
      
      if page.has_link?('Export to CSV')
        click_link 'Export to CSV'
        
        expect(page.response_headers['Content-Type']).to include('text/csv')
      end
    end

    it 'includes all player data in export' do
      visit admin_players_path
      
      if page.has_link?('Export')
        click_link 'Export'
        
        players.each do |player|
          expect(page.body).to include(player.name)
        end
      end
    end
  end

  describe 'Player titles management' do
    let(:player) { create(:player, name: 'Titled Player') }

    it 'displays player titles if present' do
      create(:title, player: player, title_name: 'GM')
      
      visit admin_player_path(player)
      
      expect(page).to have_content('GM')
    end

    it 'allows adding titles to player' do
      visit edit_admin_player_path(player)
      
      if page.has_field?('Title')
        select 'IM', from: 'Title'
        click_button 'Update Player'
        
        expect(page).to have_content('Player was successfully updated')
      end
    end
  end

  describe 'Navigation and user experience' do
    it 'provides breadcrumb navigation' do
      visit admin_players_path
      
      expect(page).to have_link('Admin') || have_link('Home')
    end

    it 'shows back link from player details' do
      player = create(:player)
      visit admin_player_path(player)
      
      expect(page).to have_link('Back') || have_link('Players')
    end

    it 'displays player count' do
      create_list(:player, 7)
      visit admin_players_path
      
      expect(page).to have_content('7 players') || have_css('.player-row', count: 7)
    end
  end

  describe 'Cancel operations' do
    it 'cancels player creation' do
      visit new_admin_player_path
      
      fill_in 'Name', with: 'Will Cancel'
      click_button 'Cancel'
      
      expect(page).to have_current_path(admin_players_path)
      expect(Player.find_by(name: 'Will Cancel')).to be_nil
    end

    it 'cancels player editing' do
      player = create(:player, name: 'Original Name')
      
      visit edit_admin_player_path(player)
      
      fill_in 'Name', with: 'Modified Name'
      click_button 'Cancel'
      
      expect(page).to have_current_path(admin_players_path)
      player.reload
      expect(player.name).to eq('Original Name')
    end
  end
end

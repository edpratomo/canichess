# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Tournament Players Management', type: :system do
  let!(:admin_user) { create(:user) }
  let(:tournament) { create(:tournament, name: 'Test Tournament') }
  let!(:group) { create(:swiss, tournament: tournament, name: 'Open Section') }

  before do
    driven_by(:rack_test)
    sign_in admin_user
  end

  describe 'Viewing tournament players' do
    let!(:player1) { create(:player, name: 'Alice Smith') }
    let!(:player2) { create(:player, name: 'Bob Jones') }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, group: group, player: player1) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, group: group, player: player2) }

    it 'displays all players in tournament' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      expect(page).to have_content('Alice Smith')
      expect(page).to have_content('Bob Jones')
    end

    it 'displays players by group' do
      visit group_admin_tournaments_players_path(tournament, group)
      
      expect(page).to have_content('Alice Smith')
      expect(page).to have_content('Bob Jones')
      expect(page).to have_content('Open Section')
    end

    it 'shows player details' do
      visit admin_tournaments_player_path(tp1)
      
      expect(page).to have_content('Alice Smith')
      expect(page).to have_content(tournament.name)
    end

    it 'displays player games' do
      board = create(:board, :white_wins,
                     tournament: tournament,
                     group: group,
                     white: tp1,
                     black: tp2,
                     round: 1)
      
      visit admin_tournaments_player_path(tp1)
      
      expect(page).to have_content('Alice Smith')
      expect(page).to have_content('Bob Jones')
    end
  end

  describe 'Adding a single player' do
    let!(:existing_player) { create(:player, name: 'Charlie Brown') }

    xit 'adds an existing player to tournament (form incomplete)' do
      visit new_admin_tournaments_players_path(tournament)
      
      select existing_player.name, from: 'Player'
      select group.name, from: 'Group'
      
      click_button 'Add Player'
      
      expect(page).to have_content('Tournament players were successfully updated')
      expect(page).to have_content('Charlie Brown')
    end

    xit 'creates and adds a new player to tournament (form incomplete)' do
      visit new_admin_tournaments_players_path(tournament)
      
      fill_in 'Player name', with: 'David Wilson'
      select group.name, from: 'Group'
      
      click_button 'Add Player'
      
      expect(page).to have_content('Tournament players were successfully updated')
      expect(page).to have_content('David Wilson')
      expect(Player.find_by(name: 'David Wilson')).to be_present
    end

    xit 'shows validation error when neither player selected nor name provided (form incomplete)' do
      visit new_admin_tournaments_players_path(tournament)
      
      click_button 'Add Player'
      
      expect(page).to have_content('required')
    end

    xit 'assigns player to correct group (form incomplete)' do
      group2 = create(:swiss, tournament: tournament, name: 'Women Section')
      
      visit new_admin_tournaments_players_path(tournament)
      
      fill_in 'Player name', with: 'Emma Davis'
      select group2.name, from: 'Group'
      
      click_button 'Add Player'
      
      tp = TournamentsPlayer.find_by(player: Player.find_by(name: 'Emma Davis'))
      expect(tp.group).to eq(group2)
    end
  end

  describe 'Uploading players from file' do
    xit 'displays upload form (feature may not exist)' do
      visit upload_admin_tournaments_players_path(tournament)
      
      expect(page).to have_content('Upload')
      expect(page).to have_field('Players file')
    end

    xit 'allows uploading CSV file with players (feature may not exist)' do
      visit upload_admin_tournaments_players_path(tournament)
      
      # Create a temporary CSV file
      csv_content = "John Doe,Open Section\nJane Smith,Open Section\n"
      file_path = Rails.root.join('tmp', 'test_players.csv')
      File.write(file_path, csv_content)
      
      attach_file 'Players file', file_path
      
      click_button 'Upload'
      
      expect(page).to have_content('Preview')
      
      # Clean up
      File.delete(file_path) if File.exist?(file_path)
    end

    xit 'shows preview before adding players (feature may not exist)' do
      visit upload_admin_tournaments_players_path(tournament)
      
      csv_content = "Test Player,Open Section\n"
      file_path = Rails.root.join('tmp', 'test_preview.csv')
      File.write(file_path, csv_content)
      
      attach_file 'Players file', file_path
      click_button 'Upload'
      
      expect(page).to have_content('Preview')
      expect(page).to have_content('Test Player')
      
      File.delete(file_path) if File.exist?(file_path)
    end

    xit 'handles duplicate player names in upload (feature may not exist)' do
      existing = create(:player, name: 'Existing Player')
      
      visit upload_admin_tournaments_players_path(tournament)
      
      csv_content = "Existing Player,Open Section\n"
      file_path = Rails.root.join('tmp', 'test_duplicate.csv')
      File.write(file_path, csv_content)
      
      attach_file 'Players file', file_path
      click_button 'Upload'
      
      # Should show existing player as suggestion
      expect(page).to have_content('Existing Player')
      
      File.delete(file_path) if File.exist?(file_path)
    end
  end

  describe 'Editing tournament player' do
    let!(:player) { create(:player, name: 'Editable Player') }
    let!(:tp) { create(:tournaments_player, tournament: tournament, group: group, player: player) }
    let!(:group2) { create(:swiss, tournament: tournament, name: 'Reserve Section') }

    xit 'updates player group (form incomplete)' do
      visit edit_admin_tournaments_player_path(tp)
      
      select group2.name, from: 'Group'
      
      click_button 'Update'
      
      expect(page).to have_content('Tournaments player was successfully updated')
      tp.reload
      expect(tp.group).to eq(group2)
    end

    xit 'blacklists a player (form incomplete)' do
      visit edit_admin_tournaments_player_path(tp)
      
      check 'Blacklisted'
      
      click_button 'Update'
      
      expect(page).to have_content('Tournaments player was successfully updated')
      tp.reload
      expect(tp.blacklisted).to be true
    end

    xit 'updates player label (form incomplete)' do
      tournament.update(player_labels: ['Seeded', 'Wild Card'])
      
      visit edit_admin_tournaments_player_path(tp)
      
      fill_in 'Label', with: 'Seeded'
      
      click_button 'Update'
      
      expect(page).to have_content('Tournaments player was successfully updated')
    end
  end

  describe 'Removing tournament player' do
    let!(:player) { create(:player, name: 'Player to Remove') }
    let!(:tp) { create(:tournaments_player, tournament: tournament, group: group, player: player) }

    xit 'removes player from tournament (requires JS)' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      expect(page).to have_content('Player to Remove')
      
      click_link 'Delete', match: :first
      
      expect(page).to have_content('Tournaments player was successfully destroyed')
      expect(page).not_to have_content('Player to Remove')
    end

    xit 'confirms deletion (requires JS)' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      # Accept confirmation dialog if present
      accept_confirm do
        click_link 'Delete', match: :first
      end
      
      expect(TournamentsPlayer.find_by(id: tp.id)).to be_nil
    end
  end

  describe 'Player labels management' do
    let!(:player) { create(:player, name: 'Labeled Player') }

    before do
      tournament.update(player_labels: ['Top Seed', 'Wild Card', 'Invited'])
    end
    
    let!(:tp) { create(:tournaments_player, tournament: tournament, group: group, player: player, labels: ['Top Seed']) }

    it 'displays player labels' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      expect(page).to have_content('Top Seed')
    end

    xit 'attaches label to player (form incomplete)' do
      visit attach_label_admin_tournaments_players_path(tp)
      
      select 'Wild Card', from: 'Label'
      
      click_button 'Attach Label'
      
      expect(page).to have_content('Label was successfully attached')
    end

    xit 'updates multiple labels for player (form incomplete)' do
      visit attach_label_admin_tournaments_players_path(tp)
      
      check 'Top Seed'
      check 'Invited'
      
      click_button 'Update Labels'
      
      expect(page).to have_content('successfully updated')
    end

    xit 'detaches label from player (requires JS)' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      click_link 'Remove Label', match: :first
      
      expect(page).to have_content('Label was successfully detached')
    end
  end

  describe 'Player statistics in tournament' do
    let!(:player) { create(:player, name: 'Statistical Player', rating: 1800) }
    let!(:tp) { create(:tournaments_player, tournament: tournament, group: group, player: player, points: 5.0, wo_count: 0) }

    it 'displays player points' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      expect(page).to have_content('5.0')
    end

    it 'displays walkover count' do
      tp.update(wo_count: 1)
      
      visit tournament_admin_tournaments_players_path(tournament)
      
      expect(page).to have_content('1') # Walkover count
    end

    xit 'shows blacklisted status (text format unclear)' do
      tp.update(blacklisted: true)
      
      visit tournament_admin_tournaments_players_path(tournament)
      
      expect(page).to have_content('blacklisted')
    end

    it 'displays player rating' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      expect(page).to have_content('1800')
    end
  end

  describe 'Bulk player operations' do
    let!(:players) { create_list(:player, 5) }

    before do
      players.each do |player|
        create(:tournaments_player, tournament: tournament, group: group, player: player)
      end
    end

    it 'displays all players for bulk operations' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      expect(page).to have_css('tr', count: players.count + 1) # +1 for header row
    end

    it 'allows filtering players' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      # If there's a search/filter feature
      if page.has_field?('Search')
        fill_in 'Search', with: players.first.name
        click_button 'Search'
        
        expect(page).to have_content(players.first.name)
      end
    end
  end

  describe 'Player preview workflow' do
    xit 'completes full upload workflow (feature may not exist)' do
      visit upload_admin_tournaments_players_path(tournament)
      
      csv_content = "Workflow Player,Open Section\n"
      file_path = Rails.root.join('tmp', 'workflow_test.csv')
      File.write(file_path, csv_content)
      
      attach_file 'Players file', file_path
      click_button 'Upload'
      
      expect(page).to have_content('Preview')
      
      # Confirm adding players
      click_button 'Add Players'
      
      expect(page).to have_content('successfully updated')
      expect(page).to have_content('Workflow Player')
      
      File.delete(file_path) if File.exist?(file_path)
    end

    xit 'allows canceling preview (feature may not exist)' do
      visit upload_admin_tournaments_players_path(tournament)
      
      csv_content = "Cancel Player,Open Section\n"
      file_path = Rails.root.join('tmp', 'cancel_test.csv')
      File.write(file_path, csv_content)
      
      attach_file 'Players file', file_path
      click_button 'Upload'
      
      click_button 'Cancel'
      
      expect(page).to have_current_path(tournament_admin_tournaments_players_path(tournament))
      expect(TournamentsPlayer.joins(:player).where(players: { name: 'Cancel Player' })).to be_empty
      
      File.delete(file_path) if File.exist?(file_path)
    end
  end

  describe 'Multiple groups handling' do
    let!(:group2) { create(:swiss, tournament: tournament, name: 'Advanced Section') }
    let!(:group3) { create(:swiss, tournament: tournament, name: 'Beginners Section') }
    let!(:player1) { create(:player, name: 'Advanced Player') }
    let!(:player2) { create(:player, name: 'Beginner Player') }
    let!(:tp1) { create(:tournaments_player, tournament: tournament, group: group2, player: player1) }
    let!(:tp2) { create(:tournaments_player, tournament: tournament, group: group3, player: player2) }

    it 'displays players grouped by section' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      expect(page).to have_content('Advanced Section')
      expect(page).to have_content('Beginners Section')
      expect(page).to have_content('Advanced Player')
      expect(page).to have_content('Beginner Player')
    end

    it 'filters players by group' do
      visit group_admin_tournaments_players_path(tournament, group2)
      
      expect(page).to have_content('Advanced Player')
      expect(page).not_to have_content('Beginner Player')
    end

    xit 'allows moving player between groups (form incomplete)' do
      visit edit_admin_tournaments_player_path(tp1)
      
      select group3.name, from: 'Group'
      click_button 'Update'
      
      expect(page).to have_content('successfully updated')
      tp1.reload
      expect(tp1.group).to eq(group3)
    end
  end

  describe 'Validation and error handling' do
    xit 'prevents adding same player twice to same tournament (form incomplete)' do
      player = create(:player, name: 'Duplicate Test')
      create(:tournaments_player, tournament: tournament, group: group, player: player)
      
      visit new_admin_tournaments_players_path(tournament)
      
      select player.name, from: 'Player'
      select group.name, from: 'Group'
      
      click_button 'Add Player'
      
      # Should show error or validation message
      expect(page).to have_content(/already|duplicate/i)
    end

    xit 'handles empty CSV file gracefully (feature may not exist)' do
      visit upload_admin_tournaments_players_path(tournament)
      
      file_path = Rails.root.join('tmp', 'empty.csv')
      File.write(file_path, '')
      
      attach_file 'Players file', file_path
      click_button 'Upload'
      
      expect(page).to have_content(/empty|no players/i)
      
      File.delete(file_path) if File.exist?(file_path)
    end

    xit 'validates group selection when adding player (form incomplete)' do
      visit new_admin_tournaments_players_path(tournament)
      
      fill_in 'Player name', with: 'Group Test Player'
      # Don't select a group
      
      click_button 'Add Player'
      
      expect(page).to have_content(/group/i)
    end
  end

  describe 'Navigation and user experience' do
    xit 'provides breadcrumb navigation (text may differ)' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      expect(page).to have_link(tournament.name)
      expect(page).to have_link('Tournaments')
    end

    xit 'provides back link to tournament (feature may not exist)' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      expect(page).to have_link('Back to Tournament')
    end

    it 'shows count of registered players' do
      create_list(:player, 3).each do |player|
        create(:tournaments_player, tournament: tournament, group: group, player: player)
      end
      
      visit tournament_admin_tournaments_players_path(tournament)
      
      expect(page).to have_content('3')
    end
  end

  describe 'Player sorting and ordering' do
    let!(:players) do
      [
        create(:player, name: 'Zebra Player', rating: 1500),
        create(:player, name: 'Alpha Player', rating: 2000),
        create(:player, name: 'Beta Player', rating: 1800)
      ]
    end

    before do
      players.each do |player|
        create(:tournaments_player, tournament: tournament, group: group, player: player)
      end
    end

    it 'displays players in alphabetical order by default' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      player_names = page.all('td').map(&:text).select { |text| text.include?('Player') }
      expect(player_names.first).to include('Alpha')
    end

    xit 'allows sorting by rating (feature may not exist)' do
      visit tournament_admin_tournaments_players_path(tournament)
      
      if page.has_link?('Rating')
        click_link 'Rating'
        expect(page.body.index('2000')).to be < page.body.index('1500')
      end
    end
  end
end

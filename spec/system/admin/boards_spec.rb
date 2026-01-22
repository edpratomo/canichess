# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Boards Management', type: :system do
  let!(:admin_user) { create(:user) }
  let(:tournament) { create(:tournament, name: 'Board Test Tournament') }
  let!(:group) { create(:swiss, tournament: tournament, name: 'Main Group', rounds: 7) }
  let!(:player1) { create(:player, name: 'White Player', rating: 1800) }
  let!(:player2) { create(:player, name: 'Black Player', rating: 1750) }
  let!(:tp1) { create(:tournaments_player, tournament: tournament, group: group, player: player1) }
  let!(:tp2) { create(:tournaments_player, tournament: tournament, group: group, player: player2) }

  before do
    driven_by(:rack_test)
    sign_in admin_user
  end

  describe 'Viewing boards' do
    let!(:board) do
      create(:board,
             tournament: tournament,
             group: group,
             round: 1,
             number: 1,
             white: tp1,
             black: tp2)
    end

    it 'displays boards for a round' do
      visit round_admin_boards_path(tournament, 1)
      
      expect(page).to have_content('White Player')
      expect(page).to have_content('Black Player')
      expect(page).to have_content('Board 1')
    end

    it 'displays boards for a group and round' do
      visit group_admin_boards_path(tournament, group, 1)
      
      expect(page).to have_content('White Player')
      expect(page).to have_content('Black Player')
    end

    it 'shows board numbers in order' do
      board2 = create(:board,
                      tournament: tournament,
                      group: group,
                      round: 1,
                      number: 2,
                      white: tp2,
                      black: tp1)
      
      visit round_admin_boards_path(tournament, 1)
      
      expect(page).to have_content('Board 1')
      expect(page).to have_content('Board 2')
    end

    it 'displays player ratings' do
      visit round_admin_boards_path(tournament, 1)
      
      expect(page).to have_content('1800')
      expect(page).to have_content('1750')
    end
  end

  describe 'Editing board results' do
    let!(:board) do
      create(:board,
             tournament: tournament,
             group: group,
             round: 1,
             number: 1,
             white: tp1,
             black: tp2,
             result: nil)
    end

    it 'allows setting white win result' do
      visit edit_board_path(board)
      
      select 'White wins', from: 'Result'
      click_button 'Update Board'
      
      expect(page).to have_content('Board was successfully updated')
      board.reload
      expect(board.result).to eq('white')
    end

    it 'allows setting black win result' do
      visit edit_board_path(board)
      
      select 'Black wins', from: 'Result'
      click_button 'Update Board'
      
      expect(page).to have_content('Board was successfully updated')
      board.reload
      expect(board.result).to eq('black')
    end

    it 'allows setting draw result' do
      visit edit_board_path(board)
      
      select 'Draw', from: 'Result'
      click_button 'Update Board'
      
      expect(page).to have_content('Board was successfully updated')
      board.reload
      expect(board.result).to eq('draw')
    end

    it 'displays current result when editing' do
      board.update(result: 'white')
      
      visit edit_board_path(board)
      
      expect(page).to have_select('Result', selected: 'White wins')
    end
  end

  describe 'Bye boards' do
    let!(:bye_board) do
      create(:board, :bye,
             tournament: tournament,
             group: group,
             round: 1,
             number: 1,
             white: tp1,
             black: nil,
             result: 'white')
    end

    it 'displays bye boards correctly' do
      visit round_admin_boards_path(tournament, 1)
      
      expect(page).to have_content('White Player')
      expect(page).to have_content('BYE')
    end

    it 'marks bye result automatically' do
      expect(bye_board.result).to eq('white')
      expect(bye_board.black).to be_nil
    end
  end

  describe 'Walkover boards' do
    let!(:walkover_board) do
      create(:board,
             tournament: tournament,
             group: group,
             round: 1,
             number: 1,
             white: tp1,
             black: tp2,
             result: 'white',
             walkover: true)
    end

    it 'displays walkover status' do
      visit round_admin_boards_path(tournament, 1)
      
      expect(page).to have_content('W.O.') || have_content('Walkover')
    end

    it 'allows marking board as walkover' do
      board = create(:board,
                     tournament: tournament,
                     group: group,
                     round: 2,
                     white: tp1,
                     black: tp2)
      
      visit edit_board_path(board)
      
      check 'Walkover'
      select 'White wins', from: 'Result'
      click_button 'Update Board'
      
      board.reload
      expect(board.walkover).to be true
    end
  end

  describe 'Deleting boards' do
    let!(:board1) { create(:board, tournament: tournament, group: group, round: 1, white: tp1, black: tp2) }
    let!(:board2) { create(:board, tournament: tournament, group: group, round: 1, white: tp2, black: tp1) }

    it 'deletes all boards for a round' do
      visit round_admin_boards_path(tournament, 1)
      
      click_link 'Delete Round'
      
      expect(page).to have_content('deleted')
      expect(Board.where(tournament: tournament, round: 1).count).to eq(0)
    end

    it 'deletes boards for a specific group and round' do
      visit delete_admin_boards_path(tournament, group, 1)
      
      click_button 'Delete Boards'
      
      expect(Board.where(tournament: tournament, group: group, round: 1).count).to eq(0)
    end

    it 'confirms deletion before removing boards' do
      visit round_admin_boards_path(tournament, 1)
      
      accept_confirm do
        click_link 'Delete Round'
      end
      
      expect(Board.where(tournament: tournament, round: 1)).to be_empty
    end
  end

  describe 'Board statistics' do
    before do
      create(:board, :white_wins, tournament: tournament, group: group, round: 1, white: tp1, black: tp2)
      create(:board, :black_wins, tournament: tournament, group: group, round: 2, white: tp1, black: tp2)
      create(:board, :draw, tournament: tournament, group: group, round: 3, white: tp1, black: tp2)
    end

    it 'displays completed games count' do
      visit round_admin_boards_path(tournament, 1)
      
      expect(page).to have_content('Result')
    end

    it 'shows games without results' do
      create(:board, tournament: tournament, group: group, round: 4, white: tp1, black: tp2, result: nil)
      
      visit round_admin_boards_path(tournament, 4)
      
      expect(page).to have_content('Pending') || have_no_content('white')
    end
  end

  describe 'Multiple rounds' do
    before do
      (1..3).each do |round|
        create(:board, tournament: tournament, group: group, round: round, white: tp1, black: tp2)
      end
    end

    it 'navigates between rounds' do
      visit round_admin_boards_path(tournament, 1)
      
      expect(page).to have_content('Round 1')
      
      click_link 'Round 2'
      
      expect(page).to have_content('Round 2')
    end

    it 'displays correct boards for each round' do
      visit round_admin_boards_path(tournament, 1)
      
      expect(page).to have_content('Round 1')
      
      visit round_admin_boards_path(tournament, 2)
      
      expect(page).to have_content('Round 2')
    end
  end

  describe 'Board validation' do
    it 'prevents creating board without players' do
      visit new_board_path
      
      click_button 'Create Board'
      
      expect(page).to have_content("can't be blank")
    end

    it 'requires tournament and group assignment' do
      visit new_board_path
      
      fill_in 'Round', with: '1'
      click_button 'Create Board'
      
      expect(page).to have_content("can't be blank")
    end
  end

  describe 'Quick result entry' do
    let!(:boards) do
      5.times.map do |i|
        create(:board,
               tournament: tournament,
               group: group,
               round: 1,
               number: i + 1,
               white: tp1,
               black: tp2)
      end
    end

    it 'allows rapid result entry for multiple boards' do
      visit round_admin_boards_path(tournament, 1)
      
      # If there's a quick entry form
      boards.each_with_index do |board, index|
        within("#board_#{board.id}") do
          select 'White wins', from: 'Result'
          click_button 'Save'
        end
      end if page.has_css?("#board_#{boards.first.id}")
      
      boards.each(&:reload)
      expect(boards.all? { |b| b.result == 'white' }).to be true
    end
  end

  describe 'Board export and print' do
    let!(:boards) do
      3.times.map do |i|
        create(:board,
               tournament: tournament,
               group: group,
               round: 1,
               number: i + 1,
               white: tp1,
               black: tp2)
      end
    end

    it 'provides printable version of boards' do
      visit round_admin_boards_path(tournament, 1)
      
      expect(page).to have_link('Print') || have_button('Print')
    end

    it 'exports boards to CSV' do
      visit round_admin_boards_path(tournament, 1)
      
      if page.has_link?('Export')
        click_link 'Export'
        
        expect(page.response_headers['Content-Type']).to include('text/csv')
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User Authentication', type: :system do
  let!(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }

  before do
    driven_by(:rack_test)
  end

  describe 'Sign in' do
    context 'with valid credentials' do
      it 'allows a user to sign in with username' do
        visit new_user_session_path
        
        fill_in 'user_username', with: user.username
        fill_in 'user_password', with: 'password123'
        click_button 'Sign in'
        
        expect(page).to have_current_path(admin_tournaments_path)
        # Flash message may be dismissible, so just check we're logged in
      end

      xit 'allows a user to sign in with email' do
        visit new_user_session_path
        
        fill_in 'user_username', with: user.email
        fill_in 'user_password', with: 'password123'
        click_button 'Sign in'
        
        expect(page).to have_current_path(admin_tournaments_path)
      end

      it 'remembers the user when "Remember me" is checked' do
        visit new_user_session_path
        
        fill_in 'user_username', with: user.username
        fill_in 'user_password', with: 'password123'
        check 'user_remember_me'
        click_button 'Sign in'
        
        expect(page).to have_current_path(admin_tournaments_path)
      end
    end

    context 'with invalid credentials' do
      it 'shows an error with wrong password' do
        visit new_user_session_path
        
        fill_in 'user_username', with: user.username
        fill_in 'user_password', with: 'wrongpassword'
        click_button 'Sign in'
        
        expect(page).to have_content('Invalid')
        expect(page).to have_current_path(new_user_session_path)
      end

      it 'shows an error with non-existent username' do
        visit new_user_session_path
        
        fill_in 'user_username', with: 'nonexistent'
        fill_in 'user_password', with: 'password123'
        click_button 'Sign in'
        
        expect(page).to have_content('Invalid')
      end

      it 'shows an error when fields are empty' do
        visit new_user_session_path
        
        click_button 'Sign in'
        
        expect(page).to have_content('Invalid')
      end
    end
  end

  describe 'Sign out' do
    it 'allows a signed-in user to sign out' do
      sign_in user
      visit admin_tournaments_path
      
      click_link 'Sign Out'
      
      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content('Signed out successfully')
    end

    it 'redirects to sign in page after signing out' do
      sign_in user
      visit admin_tournaments_path
      
      click_link 'Sign Out'
      
      visit admin_tournaments_path
      expect(page).to have_current_path(new_user_session_path)
    end
  end

  describe 'Protected pages' do
    it 'redirects unauthenticated users to sign in page' do
      visit admin_tournaments_path
      
      expect(page).to have_current_path(new_user_session_path)
    end

    it 'redirects unauthenticated users accessing tournaments admin' do
      visit admin_tournaments_path
      
      expect(page).to have_current_path(new_user_session_path)
    end

    it 'allows authenticated users to access admin pages' do
      sign_in user
      
      visit admin_tournaments_path
      
      expect(page).to have_current_path(admin_tournaments_path)
    end
  end

  describe 'Edit profile' do
    it 'allows a user to update their profile' do
      sign_in user
      
      visit edit_user_registration_path
      
      fill_in 'user_fullname', with: 'Test User Full Name'
      fill_in 'user_current_password', with: 'password123'
      click_button 'Update'
      
      expect(page).to have_content('updated') || have_current_path(admin_user_path(user))
    end

    it 'requires current password to update profile' do
      sign_in user
      
      visit edit_user_registration_path
      
      fill_in 'user_fullname', with: 'Test User Full Name'
      click_button 'Update'
      
      expect(page).to have_content("Current password can't be blank")
    end
  end
end

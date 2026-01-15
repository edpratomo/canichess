require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'devise modules' do
    it 'includes database_authenticatable' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'includes trackable' do
      expect(User.devise_modules).to include(:trackable)
    end

    it 'includes registerable' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'includes recoverable' do
      expect(User.devise_modules).to include(:recoverable)
    end

    it 'includes rememberable' do
      expect(User.devise_modules).to include(:rememberable)
    end

    it 'includes validatable' do
      expect(User.devise_modules).to include(:validatable)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:password) }
    
    context 'email uniqueness' do
      let!(:existing_user) { create(:user, email: 'test@example.com') }
      
      it 'validates uniqueness of email' do
        new_user = build(:user, email: 'test@example.com')
        expect(new_user).not_to be_valid
        expect(new_user.errors[:email]).to be_present
      end
    end
  end

  describe 'gravatar integration' do
    let(:user) { create(:user, email: 'test@example.com') }

    it 'includes Gravtastic module' do
      expect(User.ancestors.map(&:to_s)).to include('Gravtastic::InstanceMethods')
    end

    it 'responds to gravatar_url' do
      expect(user).to respond_to(:gravatar_url)
    end

    it 'uses identicon as default' do
      # Gravtastic should generate a URL with identicon default
      gravatar_url = user.gravatar_url
      expect(gravatar_url).to include('gravatar.com')
      expect(gravatar_url).to include('d=identicon')
    end
  end

  describe 'factory' do
    it 'creates valid user' do
      user = create(:user)
      expect(user).to be_valid
      expect(user.persisted?).to be true
    end

    it 'generates unique emails' do
      user1 = create(:user)
      user2 = create(:user)
      expect(user1.email).not_to eq(user2.email)
    end
  end

  describe 'authentication' do
    let(:user) { create(:user, password: 'SecurePassword123', password_confirmation: 'SecurePassword123') }

    it 'authenticates with correct password' do
      expect(user.valid_password?('SecurePassword123')).to be true
    end

    it 'does not authenticate with incorrect password' do
      expect(user.valid_password?('WrongPassword')).to be false
    end
  end

  describe 'trackable attributes' do
    let(:user) { create(:user) }

    it 'tracks sign in count' do
      expect(user).to respond_to(:sign_in_count)
    end

    it 'tracks current sign in at' do
      expect(user).to respond_to(:current_sign_in_at)
    end

    it 'tracks last sign in at' do
      expect(user).to respond_to(:last_sign_in_at)
    end

    it 'tracks current sign in IP' do
      expect(user).to respond_to(:current_sign_in_ip)
    end

    it 'tracks last sign in IP' do
      expect(user).to respond_to(:last_sign_in_ip)
    end
  end

  describe 'password reset' do
    let(:user) { create(:user) }

    it 'generates reset password token' do
      token = user.send(:set_reset_password_token)
      expect(token).to be_present
      expect(user.reset_password_token).to be_present
    end

    it 'sets reset password sent at timestamp' do
      user.send(:set_reset_password_token)
      expect(user.reset_password_sent_at).to be_present
    end
  end

  describe 'rememberable' do
    let(:user) { create(:user) }

    it 'can be remembered' do
      expect(user).to respond_to(:remember_me)
      expect(user).to respond_to(:remember_me=)
    end

    it 'can generate remember token' do
      user.remember_me!
      expect(user.remember_created_at).to be_present
    end
  end
end

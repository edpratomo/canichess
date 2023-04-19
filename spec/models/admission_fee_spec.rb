require 'rails_helper'

RSpec.describe AdmissionFee, type: :model do
  before(:each) do
    @admission_fee = create(:admission_fee)
    @expired_admission_fee = create(:admission_fee, amount: 50_000, active_since: DateTime.now.months_ago(1))
    @future_admission_fee = create(:admission_fee, amount: 150_000, active_since: DateTime.now.months_since(2))
  end

  it "is valid with valid attributes" do
    expect(@admission_fee).to be_valid
  end

  it "returns correct current amount" do
    current_admission_fee = AdmissionFee.current
    expect(current_admission_fee).not_to be_nil
    expect(current_admission_fee.amount).to eq(@admission_fee.amount)
  end
end

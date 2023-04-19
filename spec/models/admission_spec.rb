require 'rails_helper'
require "models/concerns/invoiceable"

RSpec.describe Admission, type: :model do
  before(:each) do
    @admission = create(:admission)
    @course1 = create(:course)
    @course2 = create(:course)
  end

  it_behaves_like "invoiceable"

  it "is valid with valid attributes" do
    expect(@admission).to be_valid
  end

  it "assigns a course, but there is no fee defined" do
    current_admission_fee = AdmissionFee.current
    expect(current_admission_fee).to be_nil
    expect { @admission.courses << @course1 }.to raise_error(ActiveRecord::RecordNotSaved)
  end

  it "assigns a course, and gets an invoice, and pays it in two installments" do
    admission_fee = create(:admission_fee)
    current_admission_fee = AdmissionFee.current

    expect(current_admission_fee).not_to be_nil
    expect(current_admission_fee.amount).to eq(admission_fee.amount)

    # add a course to this admission
    @admission.courses << @course1
    expect(@admission.courses.first).to eq(@course1)

    # invoice is automatically generated for this admission
    expect(@admission.invoices.size).to eq(1)
    expect(@admission.invoices.first.amount).to eq(current_admission_fee.amount)

    invoice1 = @admission.invoices.first
    expect(invoice1.paid).to be false
    # first installment
    invoice1.pay(invoice1.amount / 2, "homer")
    expect(invoice1.paid).to be false
    # second installment
    invoice1.pay(invoice1.amount / 2, "homer")
    expect(invoice1.paid).to be true
  end

  it "assigns two courses, and gets two invoices, and pays the first invoice" do
    current_admission_fee = AdmissionFee.current
    expect(current_admission_fee).to be_nil

    admission_fee = create(:admission_fee)
    current_admission_fee = AdmissionFee.current
    expect(current_admission_fee).not_to be_nil
    expect(current_admission_fee.amount).to eq(admission_fee.amount)

    # add courses to this admission
    @admission.courses << @course1
    @admission.courses << @course2

    # automatically generated invoices
    expect(@admission.invoices.size).to eq(2)
    expect(@admission.invoices.first.amount).to eq(current_admission_fee.amount)

    # pay the first invoice
    invoice1 = @admission.invoices.first
    expect(invoice1.paid).to be false
    invoice1.pay(invoice1.amount, "homer")
    expect(invoice1.paid).to be true
  end
end

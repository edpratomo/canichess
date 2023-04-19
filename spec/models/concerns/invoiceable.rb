shared_examples "invoiceable" do
  it { is_expected.to have_many(:invoices) }
end

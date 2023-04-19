require 'rails_helper'

RSpec.describe Invoice, type: :model do
  it { is_expected.to have_db_column(:invoiceable_id).of_type(:integer) }
  it { is_expected.to have_db_column(:invoiceable_type).of_type(:text) }

  it { is_expected.to belong_to(:invoiceable) }
end

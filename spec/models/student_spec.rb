require 'rails_helper'
require "models/concerns/invoiceable"

RSpec.describe Student, type: :model do
  it_behaves_like "invoiceable"
end

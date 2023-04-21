FactoryBot.define do
  factory :admin_board, class: 'Admin::Board' do
    index { "MyString" }
    update { "MyString" }
  end

  factory :board do
    index { "MyString" }
    update { "MyString" }
  end

  factory :product do
    
  end

  factory :course do
    name { Faker::ProgrammingLanguage.unique.name }
    idn_prefix { "KOM" }
  end

  factory :admission do
    name { Faker::Name.name }
    birthplace { Faker::Address.city }
    birthdate { Faker::Date.birthday }
    sex { Faker::Gender.binary_type.downcase }
    phone { Faker::PhoneNumber.unique.cell_phone }
    email { Faker::Internet.unique.safe_email }
  end

  factory :admission_fee do
    amount { 100_000 }
    active_since { 1.second.ago }
  end
end

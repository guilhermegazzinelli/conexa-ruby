FactoryBot.define do
  factory :customer, class: Conexa::Customer do
    company_id { 3 }
    name { Faker::Company.name }
    trade_name { Faker::Company.name }
    pronunciation { Faker::Lorem.word }
    field_of_activity { Faker::Company.industry }
    profession { Faker::Job.title }
    notes { Faker::Company.catch_phrase }
    cell_number { Faker::PhoneNumber.cell_phone }
    website { Faker::Internet.domain_name }
    has_login_access { false }
    automatically_issue_nfse { %w[whenGeneratingBilling afterPaymentBilling notIssue].sample }
    notes_nfse { Faker::Lorem.sentence }

    tax_deductions { { iss: Faker::Boolean.boolean } }

    legal_person do
      {
        cnpj: Faker::Company.brazilian_company_number(formatted: true),
        foundation_date: Faker::Date.between(from: '2000-01-01', to: Date.today),
        state_inscription: Faker::Number.number(digits: 10).to_s,
        municipal_inscription: Faker::Number.number(digits: 6).to_s
      }
    end

    address do
      {
        zip_code: Faker::Address.zip_code,
        state: "MG",
        city: "Divinópolis",
        street: Faker::Address.street_name,
        number: Faker::Address.building_number,
        neighborhood: Faker::Address.community,
        additional_details: Faker::Address.secondary_address
      }
    end

    phones { Array.new(2) { Faker::PhoneNumber.phone_number } }
    emails_message { Array.new(2) { Faker::Internet.email } }
    emails_financial_messages { Array.new(2) { Faker::Internet.email(domain: 'finance') } }

    # is_networking_profile_visible { Faker::Boolean.boolean }
    # is_blocked_booking_customer_area { Faker::Boolean.boolean }
    # is_allowed_booking_outside_business_hours { Faker::Boolean.boolean }
    # internet_plan { Faker::Lorem.words(number: 2).join(' ') }
    # business_presentation { Faker::Company.catch_phrase }
    # offered_services_products { Faker::Commerce.product_name }
    # reception_orientations { Faker::Lorem.sentence }
    # mailing_orientations { Faker::Lorem.sentence }

    # mailing_address do
    #   {
    #     zip_code: Faker::Address.zip_code,
    #     state: Faker::Address.state_abbr,
    #     city: Faker::Address.city,
    #     street: Faker::Address.street_name,
    #     number: Faker::Address.building_number,
    #     neighborhood: Faker::Address.community,
    #     additional_details: Faker::Address.secondary_address,
    #     landmark: Faker::Address.street_address
    #   }
    # end

    # extension_numbers { Array.new(3) { Faker::PhoneNumber.extension } }
  end
end
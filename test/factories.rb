FactoryBot.define do
  factory :admin do
    username { "admin@example.test" }
    password { SAMPLE_PASSWORD }
    active { true }
  end

  factory :domain do
    sequence(:domain) { |n| "example#{n}.test" }
    description { "Description" }
    aliases { 30 }
    mailboxes { 30 }
    maxquota { 100 }
    active { true }

    after(:create) do |domain|
      domain.description = domain.domain
    end
  end
end

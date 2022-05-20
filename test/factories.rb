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

  factory :mailbox do
    sequence(:username) { |n| "mailbox#{n}@example.test" }
    sequence(:local_part) { |n| "mailbox#{n}" }
    sequence(:maildir) { |n| "example.test/mailbox#{n}@example.test/" }
    domain { "example.test" }
    password { SAMPLE_PASSWORD }
    name { "" }
    quota_mb { 100 }
    active { true }
  end

  factory :alias do
    sequence(:address) { |n| "address#{n}@example.test" }
    goto { "goto@example.jp" }
    domain { "example.test" }
    active { true }
  end
end

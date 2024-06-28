include PostfixAdmin

FactoryBot.define do
  # CRAM-MD5: `pw -s CRAM-MD5 -p password`
  SAMPLE_PASSWORD = "{CRAM-MD5}9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740"

  factory :admin do
    username { "admin@example.test" }
    password { SAMPLE_PASSWORD }
    active { true }
  end

  factory :domain do
    sequence(:domain) { |n| "example#{n}.test" }
    # description { "Description" }
    aliases { 30 }
    mailboxes { 30 }
    maxquota { 100 }
    active { true }

    after(:build) do |domain|
      description = "#{domain.domain} Description"
      domain.description = description unless domain.description
    end
  end

  factory :mailbox do
    # :username and :maildir will be automatically set by Mailbox
    username { nil }
    maildir { nil }
    sequence(:local_part) { |n| "mailbox#{n}" }
    # :domain expected to be set by relation
    domain { nil }
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

  factory :log do
    username { "all@example.com (192.0.2.1)" }
    domain { "example.com" }
    action { "create_domain" }
    data { "example.com" }
    timestamp { Time.now }
  end
end

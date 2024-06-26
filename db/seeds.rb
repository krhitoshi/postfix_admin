include FactoryBot::Syntax::Methods

create(:domain, domain: "example.com", description: "example.com Description")
create(:domain, domain: "example.org", description: "example.org Description")

all_admin = create(:admin, username: "all@example.com")
all_admin.rel_domains << Domain.find('ALL')
all_admin.superadmin = true if all_admin.has_superadmin_column?
all_admin.save!

admin = create(:admin, username: "admin@example.com")
domain = Domain.find('example.com')
domain.admins << admin
domain.rel_aliases   << build(:alias, address: "alias@example.com")
domain.rel_mailboxes << build(:mailbox, local_part: "user")
domain.rel_mailboxes << build(:mailbox, local_part: "user2")
domain.save!

# forward
user = Alias.find("user2@example.com").update(goto: "user2@example.com,forward@example.com")

create(:quota2, username: "user@example.com", bytes: 75 * PostfixAdmin::KB_TO_MB)

create(:log)
create(:log, action: "delete_domain", data: "user@example.com")
create(:log, domain: "example.org", data: "example.org")

[![Gem Version](https://badge.fury.io/rb/postfix_admin.png)](https://rubygems.org/gems/postfix_admin)

# PostfixAdmin

Command Line Tools of Postfix Admin

## Description

Postfix Admin Web Site http://postfixadmin.sourceforge.net/

Sourceforge page http://sourceforge.net/projects/postfixadmin/

This software supports only MySQL as database for Postfix Admin.
PostgreSQL is not supported.

Postfix Admin 2.2.0 is supported.

## Installation

Install postfix_admin as:

    $ gem install postfix_admin

## Usage

List the postfix_admin subcommands as:

    $ postfix_admin

```
Commands:
  postfix_admin account_passwd user@example.com new_password               # Change password of account
  postfix_admin add_account user@example.com password                      # Add an account
  postfix_admin add_admin admin@example.com password                       # Add an admin user
  postfix_admin add_admin_domain admin@example.com example.com             # Add admin_domain
  postfix_admin add_alias alias@example.com goto@example.net               # Add an alias
  postfix_admin add_domain example.com                                     # Add a domain
  postfix_admin admin_passwd admin@example.com new_password                # Change password of admin
  postfix_admin delete_account user@example.com                            # Delete an account
  postfix_admin delete_admin admin@example.com                             # Delete an admin
  postfix_admin delete_admin_domain admin@example.com example.com          # Delete admin_domain
  postfix_admin delete_alias alias@example.com                             # Delete an alias
  postfix_admin delete_domain example.com                                  # Delete a domain
  postfix_admin dump                                                       # Dump all data
  postfix_admin edit_account user@example.com                              # Edit an account
  postfix_admin edit_admin admin@example.com                               # Edit an admin user
  postfix_admin edit_domain example.com                                    # Edit a domain limitation
  postfix_admin help [COMMAND]                                             # Describe available commands or one specific command
  postfix_admin schemes                                                    # List all supported password schemes
  postfix_admin setup example.com password                                 # Setup a domain
  postfix_admin show [example.com | admin@example.com | user@example.com]  # Show domains or admins or mailboxes
  postfix_admin summary [example.com]                                      # Summarize the usage of PostfixAdmin
  postfix_admin version                                                    # Show postfix_admin version
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# PostfixAdmin

Command Line Tools of Postfix Admin

## Description

Postfix Admin Web Site http://postfixadmin.sourceforge.net/

Sourceforge page http://sourceforge.net/projects/postfixadmin/

This software supports only MySQL as database for Postfix Admin.
PostgreSQL is not supported.

## Installation

Install postfix_admin as:

    $ gem install postfix_admin

## Usage

List the postfix_admin subcommands as:

    $ postfix_admin

```
  postfix_admin account_passwd user@example.com new_password    # Change password of account
  postfix_admin add_account user@example.com password           # Add an account
  postfix_admin add_admin admin@example.com password            # Add an admin user
  postfix_admin add_admin_domain admin@example.com example.com  # Add admin_domain
  postfix_admin add_alias alias@example.com goto@example.net    # Add an alias
  postfix_admin add_domain example.com                          # Add a domain
  postfix_admin admin_passwd admin@example.com new_password     # Change password of admin
  postfix_admin delete_account user@example.com                 # Delete an account
  postfix_admin delete_admin admin@example.com                  # Delete an admin
  postfix_admin delete_alias alias@example.com                  # Delete an alias
  postfix_admin delete_domain example.com                       # Delete a domain
  postfix_admin help [TASK]                                     # Describe available tasks or one specific task
  postfix_admin setup example.com password                      # Setup a domain
  postfix_admin show                                            # List of domains
  postfix_admin summary [example.com]                           # Summarize the usage of PostfixAdmin
  postfix_admin super_admin admin@example.com                   # Enable super admin flag of an admin
  postfix_admin version                                         # Show postfix_admin version
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[![Gem Version](https://badge.fury.io/rb/postfix_admin.png)](https://rubygems.org/gems/postfix_admin)

# postfix_admin

Command Line Tools for Postfix Admin

## Description

* Postfix Admin (Original Web-based Application)
  + Web Site http://postfixadmin.sourceforge.net/
  + GitHub https://github.com/postfixadmin/postfixadmin

* Supports Postfix Admin 3.2

* Supports MySQL/MariaDB

* Other database engines are not supported

## Installation

Install `postfix_admin` using:

    $ gem install postfix_admin

Execute the `postfix_admin` command to generate your config file at `~/.postfix_admin.conf`:

    $ postfix_admin

Edit the file for your environment:

    $ vi ~/.postfix_admin.conf

You can see the domains on your host if the `database` parameter is set properly:

    $ postfix_admin show

## Usage

List the `postfix_admin` subcommands with:

    $ postfix_admin

```
Commands:
  postfix_admin account_passwd user@example.com new_password               # Change the password of an account
  postfix_admin add_account user@example.com password                      # Add a new account
  postfix_admin add_admin admin@example.com password                       # Add a new admin user
  postfix_admin add_admin_domain admin@example.com example.com             # Grant an admin user access to a specific domain
  postfix_admin add_alias alias@example.com goto@example.net               # Add a new alias
  postfix_admin add_domain example.com                                     # Add a new domain
  postfix_admin admin_passwd admin@example.com new_password                # Change the password of an admin user
  postfix_admin delete_account user@example.com                            # Delete an account
  postfix_admin delete_admin admin@example.com                             # Delete an admin user
  postfix_admin delete_admin_domain admin@example.com example.com          # Revoke an admin user's access to a specific domain
  postfix_admin delete_alias alias@example.com                             # Delete an alias
  postfix_admin delete_domain example.com                                  # Delete a domain
  postfix_admin dump                                                       # Dump all data
  postfix_admin edit_account user@example.com                              # Edit an account
  postfix_admin edit_admin admin@example.com                               # Edit an admin user
  postfix_admin edit_alias alias@example.com                               # Edit an alias
  postfix_admin edit_domain example.com                                    # Edit a domain
  postfix_admin help [COMMAND]                                             # Describe available commands or one specific command
  postfix_admin log                                                        # Show action logs
  postfix_admin schemes                                                    # List all supported password schemes
  postfix_admin setup example.com password                                 # Set up a domain
  postfix_admin show [example.com | admin@example.com | user@example.com]  # Display details about domains, admins, or accounts
  postfix_admin summary [example.com]                                      # Summarize the usage of PostfixAdmin
  postfix_admin version                                                    # Show postfix_admin version
```

# PostfixAdmin

Command Line Tools of PostfixAdmin

## Installation

Add this line to your application's Gemfile:

    gem 'postfix_admin'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install postfix_admin

## Usage

```
  postfix_admin add_account       # add an account
  postfix_admin add_admin         # add an admin user
  postfix_admin add_admin_domain  # add admin_domain
  postfix_admin add_alias         # add an alias
  postfix_admin add_domain        # add a domain
  postfix_admin delete_admin      # delete an admin
  postfix_admin delete_domain     # delete a domain
  postfix_admin help [TASK]       # Describe available tasks or one specific task
  postfix_admin setup             # setup a domain
  postfix_admin show              # List of domains
  postfix_admin summary           # Summarize the usage of PostfixAdmin
  postfix_admin version           # Show postfix_admin version
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

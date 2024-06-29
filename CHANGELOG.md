# CHANGELOG

## 0.3.1
  * Added `teardown` subcommand for the opposite operation of `setup`
  * `delete_domain` subcommand removes logs associated with the domain
  * Added `-s` (scheme) and `-r` (rounds) options for subcommands that require password arguments
    + Encryption rounds are supported only for `BLF-CRYPT`, `SHA256-CRYPT`, and `SHA512-CRYPT` schemes

## 0.3.0
  * Added support for table display format
  * No longer supports `dovecotpw` for password hash generation
    + Only `doveadm pw` is supported

## 0.2.1
  * Added support for the `superadmin` column in the `admin` table
  * Added `passwordhash_prefix` keyword in the configuration format for backward compatibility

## 0.2.0
  * Switched the object-relational mapper from DataMapper to ActiveRecord
  * Stored password hashes now include scheme prefixes, such as `{CRAM-MD5}` and `{PLAIN}`

## 0.1.4
  * Added `log` subcommand

## 0.1.3
  * Added support for activation and deactivation of domains, admins, and accounts
  * Added `edit_admin` subcommand

## 0.1.2
  * Added support for password hashing by doveadm (external subcommand)
  * Display active status
  * Hide passwords in list format

## 0.1.1, released 2013-05-10
  * Fixed string length issue for passwords

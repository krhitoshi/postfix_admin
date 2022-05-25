## 0.2.2
 * No longer supports `dovecotpw` for password hash generation.  
   `doveadm pw` is only supported.

## 0.2.1
 * Supported `superadmin` column of `admin` table
 * Added `passwordhash_prefix` keyword in the configuration format for backward compatibility

## 0.2.0
 * Switched its object-relational mapper from DataMapper to ActiveRecord
 * Stored password hash includes scheme prefix: like `{CRAM-MD5}`, `{PLAIN}`

## 0.1.4
 * Added "log" subcommand

## 0.1.3
 * Support for activation and deactivation of domain, admin and account
 * Added "edit_admin" subcommand

## 0.1.2
 * Support password hash by doveadm (external subcommand)
 * Show active status
 * Don't show passwords using list format

## 0.1.1, release 2013-05-10
 * Fixed string length of password

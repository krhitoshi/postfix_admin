<?php
$CONF['configured'] = true;

$CONF['database_type'] = 'mysqli';
$CONF['database_user'] = 'postfix';
$CONF['database_password'] = 'password';
$CONF['database_name'] = 'postfix';
$CONF['database_host'] = 'db';

$CONF['password_validation'] = array(
    #    '/regular expression/' => '$PALANG key (optional: + parameter)',
        '/.{5}/'                => 'password_too_short 5',      # minimum length 5 characters
        '/([a-zA-Z].*){3}/'     => 'password_no_characters 3',  # must contain at least 3 characters
        // '/([0-9].*){2}/'        => 'password_no_digits 2',      # must contain at least 2 digits
    );

$CONF['encrypt'] = 'dovecot:CRAM-MD5';

$CONF['domain_quota'] = 'NO';
$CONF['quota'] = 'YES';

// setup_password: 'password'
$CONF['setup_password'] = '87745eb0269b2f42813b23601be3231a:6e41880f73d97321f2f0b25a5ee30f57f5ab3be8';
?>

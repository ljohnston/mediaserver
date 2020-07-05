
# Postfix

Getting postfix working was something of a pain. This README exists only to
capture some potentially useful postfix-related notes.

It was hard just finding info on how to setup a postfix server when you don't
have a real domain name. This ended up being the best link I found:

https://github.com/taw00/howto/blob/master/howto-configure-send-only-email-via-smtp-relay.md

Ultimately, this is the postfix config I was able to getting things to work
with:

    # main.cf
    relayhost = [smtp.mail.yahoo.com]:587
    smtp_use_tls = yes
    smtp_sasl_auth_enable = yes
    smtp_sasl_security_options =
    smtp_sasl_password_maps = hash:/etc/postfix/sasl/sasl_passwd_yahoo
    smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
    smtp_generic_maps = hash:/etc/postfix/map/generic_map, regexp:/etc/postfix/map/regex_map_yahoo

    # sasl/sasl_passwd_yahoo
    [smtp.mail.yahoo.com]:587 lance_johnston@yahoo.com:<password>

    # map/regex_map_yahoo
    /.+@mediaserver-dev.localdomain/    lance_johnston@yahoo.com

From the link above, one of the most useful pieces of info was the following:

# These two additional settings only used if using port 465
#smtp_tls_wrappermode = yes
#smtp_tls_security_level = encrypt

Several other examples included those settings. Is was only after I stumbled
across the above and removed those lines that I was able to get anything
working.

To send a test email:

    $ date |mailx -s 'test email' johnston.lance@gmail.com

name             'cd-cu-auth'
maintainer       'Paul Allen'
maintainer_email 'pea1@cornell.edu'
license          'All rights reserved'
description       'Configures kerberos, sssd, sshd, using Cornell AD for user and group mapping.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           '0.1.0'
depends           'openssh'
depends           'krb5'
gem               'aws-sdk-core'

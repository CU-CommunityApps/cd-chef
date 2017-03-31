
# dev, test, or prod server?
default['odsee']['environment'] = 'dev'

# These attribute names are aligned with IDM scripts.conf names
default['odsee']['install']['app_dir'] = '/app/ldap'
default['odsee']['install']['install_path2'] = '/app/ldap/ds-7'
default['odsee']['install']['install_path']  = '/app/ldap/ds-7/dsee7'
default['odsee']['install']['log_path'] = '/app/log/ldap/ds-7'
default['odsee']['install']['data_path'] = '/app/data/ldap/ds-7'

default['odsee']['install']['s3bucket'] = 'cu-cs-odsee'

default['odsee']['credentials']['dmadmin_password_file_name'] = '/tmp/dmadmin_password.txt'
default['odsee']['credentials']['admin_password_file_name'] = '/tmp/admin_password.txt'
default['odsee']['credentials']['agent_password_file_name'] = '/tmp/agent_password.txt'

## Data import configuration

# Don't include the .gz suffix
default['odsee']['import']['data_file'] = 'slapd-ds1.cornell.2017_03_30_030916.ldif'
default['odsee']['import']['s3bucket'] = 'cu-cs-odsee'

# E.g., 'import_data/'
default['odsee']['import']['s3_key_prefix'] = ''



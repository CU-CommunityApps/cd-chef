

# These attribute names are aligned with IDM scripts.conf names
default[:odsee][:app_dir] = '/app/ldap'
default[:odsee][:install_path2] = default[:odsee][:app_dir]+'/ds-7'
default[:odsee][:install_path]  = default[:odsee][:install_path2]+'/dsee7'

default[:odsee][:log_path] = '/app/log/ldap/ds-7'
default[:odsee][:data_path] = '/app/data/ldap/ds-7'
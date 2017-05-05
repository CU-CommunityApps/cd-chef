# Setup passwords and certificates to be used


# Eventually, we might want to store the credentials in S3.
# IDM might be more comfortable with that than, injecting them via
# encrypted custom json.
#
# Setup temporary files containing passwords.
file node['odsee']['credentials']['admin_password_file_name'] do
  content "password123"
end

file node['odsee']['credentials']['agent_password_file_name'] do
  content "password123"
end

file node['odsee']['credentials']['dmadmin_password_file_name'] do
  content "password123"
end

###########################
# create tmp password files
###########################
# file node['odsee']['credentials']['admin_password_file_name'] do
#   content node['admin_password']['secret_key_decrypted']
#   mode '0600'
#   owner 'root'
#   group 'root'
# end

# file node['odsee']['credentials']['agent_password_file_name'] do
#   content node['agent_password']['secret_key_decrypted']
#   mode '0600'
#   owner 'root'
#   group 'root'
# end

# file node['odsee']['credentials']['dmadmin_password_file_name'] do
#   content node['dmadmin_password']['secret_key_decrypted']
#   mode '0600'
#   owner 'root'
#   group 'root'
# end

# Certificates
# TDB

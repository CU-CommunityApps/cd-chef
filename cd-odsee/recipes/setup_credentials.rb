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

# Certificates
# TDB
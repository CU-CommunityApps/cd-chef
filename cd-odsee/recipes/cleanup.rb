# Cleanup password files and other detritus after setting up the server

file node['odsee']['credentials']['admin_password_file_name'] do
  action :delete
end

file node['odsee']['credentials']['agent_password_file_name'] do
  action :delete
end

file node['odsee']['credentials']['dmadmin_password_file_name'] do
  action :delete
end

# =-=-=-=-=-
# cleanup tmp password files
# =-=-=-=-=-
# file '/tmp/admin_password.txt' do
#   action :delete
# end

# file '/tmp/agent_password.txt' do
#   action :delete
# end

# file '/tmp/dmadmin_password.txt' do
#   action :delete
# end

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

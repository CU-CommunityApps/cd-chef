file node['odsee']['credentials']['admin_password_file_name'] do
  content "password123"
end

file node['odsee']['credentials']['agent_password_file_name'] do
  content "password123"
end

file node['odsee']['credentials']['dmadmin_password_file_name'] do
  content "password123"
end
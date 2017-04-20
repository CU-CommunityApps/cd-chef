
stack = search("aws_opsworks_stack").first
#stack['name']
instance = search("aws_opsworks_instance", "self:true").first
#instance['hostname']

execute 'set-hostname' do
  command "hostname #{stack['name']}-#{instance['hostname']}"
  not_if node['hostname'].start_with?(stack['name'])
end

service 'rsyslog' do
  action :restart
end

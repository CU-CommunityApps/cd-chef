include_recipe "remote_syslog2-cookbook::default"

stack = search("aws_opsworks_stack").first
#stack['name']
instance = search("aws_opsworks_instance", "self:true").first
#instance['hostname']

node['remote_syslog2']['config']['hostname'] = "#{stack['name']}-#{instance['hostname']}"

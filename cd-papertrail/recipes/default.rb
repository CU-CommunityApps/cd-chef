stack = search("aws_opsworks_stack").first
#stack['name']
instance = search("aws_opsworks_instance", "self:true").first
#instance['hostname']

node.default['remote_syslog2']['config']['hostname'] = "#{stack['name']}-#{instance['hostname']}"

include_recipe "remote_syslog2::default"

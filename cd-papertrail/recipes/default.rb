# Override values from remote_syslog2-cookbook
# Use v0.19, instead of v0.17
node.default['remote_syslog2']['install']['download_file'] = 'https://github.com/papertrail/remote_syslog2/releases/download/v0.19/remote_syslog_linux_i386.tar.gz'
node.default['remote_syslog2']['install']['bin'] = 'remote_syslog2_0.19'

stack = search("aws_opsworks_stack").first
#stack['name']
instance = search("aws_opsworks_instance", "self:true").first
#instance['hostname']

node.default['remote_syslog2']['config']['hostname'] = "#{stack['name']}-#{instance['hostname']}"

include_recipe "remote_syslog2::default"

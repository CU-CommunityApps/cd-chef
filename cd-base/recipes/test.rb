stack = search("aws_opsworks_stack").first
#stack['name']
instance = search("aws_opsworks_instance", "self:true").first
#instance['hostname']

execute 'rsyslog-hostname' do
  command "sed -i 's/#### GLOBAL DIRECTIVES ####/#### GLOBAL DIRECTIVES ####\n$LocalHostName #{stack['name']}-#{instance['hostname']}/' /etc/rsyslog.conf"
  not_if 'grep -q LocalHostName /etc/rsyslog.conf'
end


template 'pt.conf' do
    path '/etc/rsyslog.d/pt.conf'
    source 'pt.conf.erb'
    owner 'root'
    group 'root'
    mode 0644
end

service 'rsyslog' do
  action :restart
end
include_recipe "cd-cu-auth::secrets"

package 'sssd'

template '/etc/sssd/sssd.conf' do
  source 'sssd/sssd.conf.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables({
    :sssd_config => node['sssd_config']
  })
  action :create
  notifies :restart, 'service[sssd]', :immediately
end

cookbook_file '/etc/nsswitch.conf' do
  source 'sssd/nsswitch.conf'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
  notifies :restart, 'service[sssd]', :immediately
end

service 'sssd' do
  supports :restart => true
  action :nothing
end

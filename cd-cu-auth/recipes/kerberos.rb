

include_recipe 'krb5::default'

cookbook_file '/etc/krb5.conf' do
  source 'kerberos/krb5.conf'
  owner 'root'
  group 'root'
  mode 0644
  action :create
end

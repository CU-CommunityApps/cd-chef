include_recipe "cd-cu-auth::secrets"

# Add Duo repos to the list of standard Ubuntu repos
apt_repository 'duo' do
  uri 'http://pkg.duosecurity.com/Ubuntu'
  distribution 'xenial'
  components ['main']
  key 'https://duo.com/APT-GPG-KEY-DUO'
end

# Install the duo package
package 'duo-unix'

# Configure PAM to use Duo. This file is based on configuration
# after kerberos and sssd is configured.
cookbook_file '/etc/pam.d/common-auth' do
  source 'duo/pam-common-auth'
  owner 'root'
  group 'root'
  mode '0644'
end

directory "/etc/duo" do
  owner 'root'
  group 'root'
  mode '0755'
end

# This configuration file contains secrets
template '/etc/duo/pam_duo.conf' do
  source 'duo/pam_duo.conf.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables({
    :duo_config => node['duo_config']
  })
end
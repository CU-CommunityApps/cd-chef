# This overrides the setting in attributes/sftp.rb.
# It must be listed prior to the include_recipe for openssh
# node.default['openssh']['server']['log_level'] = 'DEBUG'

node.default['openssh']['server']['permit_root_login'] = 'no'
node.default['openssh']['server']['password_authentication'] = 'no'

node.default['openssh']['server']['deny_users'] = 'root'
node.default['openssh']['server']['deny_groups'] = 'root'
groups = ['ubuntu']
node['filesystems'].each do |g|
  groups << g['ad_group']
end
node.default['openssh']['server']['allow_groups'] = groups.join(" ")

# For Duo
node.default['openssh']['server']['challenge_response_authentication'] = 'yes'
node.default['openssh']['server']['use_d_n_s'] = 'no'
#node.default['openssh']['server']['password_authentication'] = 'yes'

# configure SFTP
node.default['openssh']['server']['subsystem'] = 'sftp internal-sftp'
# If umask is desired.
# node.default['openssh']['server']['subsystem'] = 'sftp internal-sftp -u 022'
node.default['openssh']['server']['match'] = {}

node['filesystems'].each do |g|
  node.default['openssh']['server']['match']["Group #{g['ad_group']}"] =
  {
     'allow_t_c_p_forwarding' => 'no',
     'x11_forwarding' =>'no',
     'password_authentication' => 'yes',
     'chroot_directory' => '/mnt',
     'force_command' => 'internal-sftp -u 002',
   }
end

include_recipe 'openssh::default'




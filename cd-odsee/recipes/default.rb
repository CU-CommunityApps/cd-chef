
package 'unzip'
package 'glibc-devel.i686'
package 'libstdc++.i686'
package 'libstdc++-devel.i686'

stack = search('aws_opsworks_stack').first
aws_region = stack['region']

# %w[ /app /app/ldap /app/ldap/ds-7 ].each do |path|
#   directory path do
#     owner 'root'
#     group 'root'
#     mode '0755'
#   end
# end

# /app/ldap/ds-7/dsee7
install_path = node[:odsee][:install_path]

# create /app/ldap/ds-7
directory node[:odsee][:install_path2] do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end

aws_s3_file '/tmp/ofm_odsee_linux_11.1.1.7.0_64_disk1_1of1.zip' do
  bucket 'cu-cs-odsee'
  region aws_region
  remote_path 'ofm_odsee_linux_11.1.1.7.0_64_disk1_1of1.zip'
  checksum '6a04b778a32fb79c157d38206a63e66418c8c7fe381371e7a74fe9dc1ee788fa'
  use_etag  true
  action :create_if_missing
end

execute 'unzip_outer' do
  command 'unzip -o /tmp/ofm_odsee_linux_11.1.1.7.0_64_disk1_1of1.zip'
  cwd '/tmp'
  creates '/tmp/ODSEE_ZIP_Distribution/sun-dsee7.zip'
end

execute 'unzip_inner' do
  command 'unzip -o /tmp/ODSEE_ZIP_Distribution/sun-dsee7.zip -d /app/ldap/ds-7/'
  creates install_path
end

aws_s3_file '/tmp/UnlimitedJCEPolicyJDK7.zip' do
  bucket 'cu-cs-odsee'
  region aws_region
  remote_path 'UnlimitedJCEPolicyJDK7.zip'
  use_etag  true
  action :create_if_missing
end

execute 'unzip_security' do
  command 'unzip -o /tmp/UnlimitedJCEPolicyJDK7.zip'
  cwd '/tmp'
  creates '/tmp/UnlimitedJCEPolicy'
end

# cd /app/ldap/ds-7/dsee/jre/lib/security
# sudo mv local_policy.jar local_policy_old.jar
# sudo mv US_export_policy.jar US_export_policy_old.jar
# sudo mv ~/UnlimitedJCEPolicyJDK8/local_policy.jar .
# sudo mv ~/UnlimitedJCEPolicyJDK8/US_export_policy.jar .

%w[ local_policy.jar US_export_policy.jar ].each do |target_file|
  remote_file target_file do
    path install_path+'/jre/lib/security/'+target_file
    source 'file:///tmp/UnlimitedJCEPolicy/'+target_file
  end
end

admin_password_file = '/tmp/admin_password.txt'
agent_password_file = '/tmp/agent_password.txt'
dmadmin_password_file = '/tmp/dmadmin_password.txt'

file admin_password_file do
  content "password123"
end

file agent_password_file do
  content "password123"
end

file dmadmin_password_file do
  content "password123"
end

# improve this by running only if  `sudo /app/ldap/ds-7/dsee7/bin/dsccsetup status`
# does not return something like:
# ***
# DSCC Registry has been created
# Path of DSCC registry is /app/ldap/ds-7/dsee7/var/dcc/ads
# Port of DSCC registry is 3998
# ***
# http://docs.oracle.com/cd/E29127_01/doc.111170/e28967/dsccsetup-1m.htm
execute 'ads-create' do
  command 'bin/dsccsetup ads-create -w '+admin_password_file
  only_if install_path+'/bin/dsccsetup status | grep "DSCC Registry has been created"'
  cwd install_path
end

execute 'war-file-create' do
  command 'bin/dsccsetup war-file-create'
  creates install_path+'/var/dscc7.war'
  cwd install_path
end

# http://docs.oracle.com/cd/E29127_01/doc.111170/e28967/dsccagent-1m.htm#dsccagent-1m
execute 'agent-create' do
  command 'bin/dsccagent create -w '+agent_password_file
  not_if install_path+'/bin/dsccagent info'
  cwd install_path
end

# http://docs.oracle.com/cd/E29127_01/doc.111170/e28967/dsccreg-1m.htm#dsccreg-1m
# /app/ldap/ds-7/dsee7/bin/dsccreg add-agent /app/ldap/ds-7/dsee7/var/dcc/agent
execute 'agent-register' do
  command 'bin/dsccreg add-agent -G '+agent_password_file+' -w '+admin_password_file
  only_if install_path+'/bin/dsccreg list-agents -w '+admin_password_file+' | grep "0 agent(s) displayed"'
  cwd install_path
end

execute 'agent-snmp' do
  command 'bin/dsccagent enable-snmp'
  cwd install_path
end

aws_s3_file '/tmp/scripts.zip' do
  bucket 'cu-cs-odsee'
  region aws_region
  remote_path 'scripts.zip'
  use_etag  true
  action :create_if_missing
end

execute 'unzip_scripts' do
  command "unzip -o /tmp/scripts.zip -d #{install_path}/"
  creates install_path+'/scripts'
end

instance = search("aws_opsworks_instance", "self:true").first
server_name = 'aws'+node[:odsee][:environment]+'ds'+instance['hostname']

template install_path+'/scripts/scripts.conf' do
  source 'odsee/scripts.conf.erb'
  variables({
    :server_name => server_name,
    :ip => instance['private_ip']
  })
end

execute 'ldap-server' do
  command "bin/dsadm create -p 389 -P 636 -w #{dmadmin_password_file} #{install_path}/slapd-#{server_name}"
  not_if "#{install_path}/bin/dsadm info #{install_path}/slapd-#{server_name}"
  cwd install_path
end

execute 'ldap-start' do
  command "bin/dsadm start #{install_path}/slapd-#{server_name}"
  cwd install_path
end

##################################################################
# Make user, group
##################################################################

group 'ldap'

user 'ldap' do
  group 'ldap'
  home '/home/ldap'
  shell '/bin/nologin'
end

directory '/home/ldap' do
  owner 'ldap'
  group 'ldap'
  mode '0700'
end

##################################################################
# Import data
##################################################################
aws_s3_file install_path+'/resources/slapd-ds1.cornell.2017_03_30_030916.ldif.gz' do
  bucket 'cu-cs-odsee'
  region aws_region
  remote_path 'slapd-ds1.cornell.2017_03_30_030916.ldif.gz'
  use_etag  true
  action :create_if_missing
  owner 'ldap'
  group 'ldap'
end

execute 'unzip-data' do
  command 'gunzip -f slapd-ds1.cornell.2017_03_17_030919.ldif.gz'
  creates install_path+'/resources/slapd-ds1.cornell.2017_03_30_030916.ldif'
  cwd install_path+'/resources'
end


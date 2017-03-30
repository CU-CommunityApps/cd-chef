
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

install_dir = node[:odsee][:install_path]+node[:odsee][:install_dir]

directory node[:odsee][:install_path] do
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
  creates install_dir
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
  creates '/tmp/UnlimitedJCEPolicy/US_export_policy.jar'
end

# cd /app/ldap/ds-7/dsee/jre/lib/security
# sudo mv local_policy.jar local_policy_old.jar
# sudo mv US_export_policy.jar US_export_policy_old.jar
# sudo mv ~/UnlimitedJCEPolicyJDK8/local_policy.jar .
# sudo mv ~/UnlimitedJCEPolicyJDK8/US_export_policy.jar .

%w[ local_policy.jar US_export_policy.jar ].each do |target_file|
  remote_file target_file do
    path install_dir+'/jre/lib/security/'+target_file
    source 'file:///tmp/UnlimitedJCEPolicy/'+target_file
  end
end

file '/tmp/password.txt' do
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
  command 'bin/dsccsetup ads-create -w /tmp/password.txt'
  only_if 'bin/dsccsetup status | grep "DSCC Registry has been created"'
  cwd install_dir
end

execute 'war-file-create' do
  command '/app/ldap/ds-7/dsee7/bin/dsccsetup war-file-create'
  creates '/app/ldap/ds-7/dsee7/var/dscc7.war'
end

# http://docs.oracle.com/cd/E29127_01/doc.111170/e28967/dsccagent-1m.htm#dsccagent-1m
execute 'agent-create' do
  command '/app/ldap/ds-7/dsee7/bin/dsccagent create -w /tmp/password.txt'
  not_if '/app/ldap/ds-7/dsee7/bin/dsccagent info'
end

# http://docs.oracle.com/cd/E29127_01/doc.111170/e28967/dsccreg-1m.htm#dsccreg-1m
# /app/ldap/ds-7/dsee7/bin/dsccreg add-agent /app/ldap/ds-7/dsee7/var/dcc/agent
execute 'agent-register' do
  command '/app/ldap/ds-7/dsee7/bin/dsccreg add-agent -G /tmp/password.txt -w /tmp/password.txt'
  only_if '/app/ldap/ds-7/dsee7/bin/dsccreg list-agents -w /tmp/password.txt | grep "0 agent(s) displayed"'
end

execute 'agent-snmp' do
  command '/app/ldap/ds-7/dsee7/bin/dsccagent enable-snmp'
end

aws_s3_file '/tmp/scripts.zip' do
  bucket 'cu-cs-odsee'
  region aws_region
  remote_path 'scripts.zip'
  use_etag  true
  action :create_if_missing
end

execute 'unzip_scripts' do
  command 'unzip -o /tmp/scripts.zip -d /app/ldap/ds-7/dsee7/'
  creates '/app/ldap/ds-7/dsee7/scripts'
end

template '/tmp/myscript.conf' do
  source 'odsee/scripts.conf.erb'
end

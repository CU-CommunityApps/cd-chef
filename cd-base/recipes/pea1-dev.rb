
package 'unzip'
package 'glibc-devel.i686'
package 'libstdc++.i686'
package 'libstdc++-devel.i686'

# remote_file '/tmp/ofm_idm_linux_11.1.1.7.0_64_disk1_1of1.zip' do
#   source 'https://s3.amazonaws.com/cu-cs-odsee/ofm_idm_linux_11.1.1.7.0_64_disk1_1of1.zip'
#   checksum 'fe3ed97bebcbaa11e9a14e2115c90da369fd1a737a96d25e273eb0a74faa1f27'
#   etag 'd4a9f943fb331a3aa9bc41a73050852b-245'
#   use_conditional_get true
#   action :create_if_missing
# end

stack = search('aws_opsworks_stack').first
aws_region = stack['region']

aws_s3_file '/tmp/ofm_odsee_linux_11.1.1.7.0_64_disk1_1of1.zip' do
  bucket 'cu-cs-odsee'
  region aws_region
  remote_path 'ofm_odsee_linux_11.1.1.7.0_64_disk1_1of1.zip'
  checksum '6a04b778a32fb79c157d38206a63e66418c8c7fe381371e7a74fe9dc1ee788fa'
  use_etag  true
  action :create_if_missing
end

aws_s3_file '/tmp/UnlimitedJCEPolicyJDK7.zip' do
  bucket 'cu-cs-odsee'
  region aws_region
  remote_path 'UnlimitedJCEPolicyJDK7.zip'
  use_etag  true
  action :create_if_missing
end


%w[ /app /app/ldap /app/ldap/ds-7 ].each do |path|
  directory path do
    owner 'root'
    group 'root'
    mode '0755'
  end
end

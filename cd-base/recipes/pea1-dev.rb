
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

aws_s3_file '/tmp/ofm_idm_linux_11.1.1.7.0_64_disk1_1of1.zip' do
  bucket 'cu-cs-odsee'
  region aws_region
  remote_path 'ofm_idm_linux_11.1.1.7.0_64_disk1_1of1.zip'
  use_etag  true
  use_conditional_get true
  action :create_if_missing
end

stack = search('aws_opsworks_stack').first
aws_region = stack['region']

package_file = 'ubuntu14_CloudBerryLab_CloudBerryBackup_v2.0.1.131_20170310190644.deb'

aws_s3_file '/tmp/'+package_file  do
  bucket 'cu-cs-pea1'
  region aws_region
  remote_path package_file
  use_etag  true
  action :create
end

dpkg_package 'cloudberry-package' do
  source '/tmp/'+package_file
end
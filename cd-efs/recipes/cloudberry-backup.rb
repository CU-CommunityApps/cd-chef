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

# export cbb=/opt/local/CloudBerry\ Backup/bin/cbb
cbb = '/opt/local/CloudBerry Backup/bin/cbb'

execute 'cloudberry-license' do
  command "\"#{cbb}\" -e cloud-devops@cornell.edu -t ultimate"
end

# DON"T CHECK THIS IN!!!!!!

key=''
skey=''
cbaccount='s3-cloudberry-test'

execute 'cloudberry-license' do
  command "\"$cbb\" addAccount -d #{cbaccount} -st AmazonS3 -ac #{key} -sk #{skey} -c cu-cs-efs-backup-test -bp cloudberry-backup -ssl"
end

"$cbb" addBackupPlan -n plan9 -a s3-cloudberry-test -en yes -es no -f "/mnt/cu-cs-sandbox/pea1-efs-test-CC/" -f "/mnt/cu-cs-sandbox/pea1-efs-test-DD/" -f "/mnt/cu-cloud-devops/pea1-efs-test-EE/" -f "/mnt/cu-acadtech/pea1-efs-test-FF/" -c yes -bef no -dl yes -dld 0 -keep 3 -every day -workTime "00:01-23:59" -recurrencePeriod 5 -notification on -subject berrybackup

cbb option -set notification -e "email" -u "userName"
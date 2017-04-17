
chef_gem 'aws-sdk-core' do
  compile_time true
end

chef_gem 'cucloud' do
  compile_time true
end

stack = search('aws_opsworks_stack').first
region = stack['region']

require_relative "../libraries/cd-jenkins_helper.rb"

OpsWorksKMSSecretsJenkins.decrypt_attributes(region, node, 'ecs')

log 'TEST KMS DECRYPTION' do
  message "DECRYPTED DATA: [#{node['ecs']['test_decrypted']}]"
end


chef_gem 'aws-sdk-core' do
  compile_time true
end

chef_gem 'cucloud' do
  compile_time true
end

stack = search('aws_opsworks_stack').first
region = stack['region']

require_relative "../libraries/cd-base_helper.rb"

OpsWorksKMSSecretsCDBase.decrypt_attributes(region, node, 'ecs')
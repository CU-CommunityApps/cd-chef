
chef_gem 'aws-sdk-core' do
  compile_time true
end

chef_gem 'cucloud' do
  compile_time true
end

stack = search('aws_opsworks_stack').first
region = stack['region']

require_relative "../libraries/cd-cu-auth_helper.rb"

OpsWorksKMSSecrets.decrypt_attributes(region, node, 'duo_config')
OpsWorksKMSSecrets.decrypt_attributes(region, node, 'sssd_config')


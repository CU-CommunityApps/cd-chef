chef_gem 'aws-sdk-core' do
  compile_time true
end

chef_gem 'cucloud' do
  compile_time true
end

stack = search('aws_opsworks_stack').first
region = stack['region']

require_relative "../libraries/cd-cu-auth_helper.rb"

OpsWorksKMSSecrets.decrypt_attributes(region, node, 'admin_password')
OpsWorksKMSSecrets.decrypt_attributes(region, node, 'agent_password')
OpsWorksKMSSecrets.decrypt_attributes(region, node, 'dmadmin_password')

# After decryption, node['admin_password']['secret_key_decrypted'] will contain the decrypted value of node['admin_password']['secret_key_encrypted'].

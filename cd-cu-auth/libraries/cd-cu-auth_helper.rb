require 'aws-sdk-core'
require 'cucloud'

module OpsWorksKMSSecrets

  # Purpose: Decrypt attribute values in the Chef node object.
  #
  # Details:
  # - to be more efficient, this works on a top-level "branch" of the node object.
  # - attributes to be decrypted:
  #   - must have a key with suffix "_encrypted". E.g., my_data_encrypted.
  #   - the decrypted value is stored in an atttribute with the original
  #     key having the suffix removed. E.g., my_data
  # - the decrypted values are merged into the node.default chef object.
  #
  # Call like this from a OpsWorks Chef recipe:
  # stack = search('aws_opsworks_stack').first
  # region = stack['region']
  # main_nodetraverse_decrypt(region, node, 'duo_config')
  #
  def OpsWorksKMSSecrets.decrypt_attributes(region, node, top_level_key)
    Cucloud.region = region
    kms_utils = Cucloud::KmsUtils.new
    result = kms_utils.encrypt_struct(node[top_level_key])
    node.default[top_level_key] = result
  end

  def OpsWorksKMSSecrets.test1()
    kms_utils = Cucloud::KmsUtils.new
    input = JSON.parse(File.read('chef_data_test_encryption.json'))
    key_id = input['kms_key_arn']
    result = kms_utils.encrypt_struct(input, key_id)
    puts JSON.pretty_generate(result)
  end

  def OpsWorksKMSSecrets.test2()
    kms_utils = Cucloud::KmsUtils.new
    input = JSON.parse(File.read('chef_data_test_decryption.json'))
    result = kms_utils.decrypt_struct(input)
    puts JSON.pretty_generate(result)
  end
end
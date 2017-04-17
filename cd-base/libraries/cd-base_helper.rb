require 'aws-sdk-core'
require 'cucloud'

module OpsWorksKMSSecretsCDBase

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
  def OpsWorksKMSSecretsCDBase.decrypt_attributes(region, node, top_level_key)
    Cucloud.region = region
    kms_utils = Cucloud::KmsUtils.new
    result = kms_utils.decrypt_struct(node[top_level_key])
    node.default[top_level_key] = result
  end
end
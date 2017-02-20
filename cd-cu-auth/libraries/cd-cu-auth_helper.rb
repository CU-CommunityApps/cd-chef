require 'aws-sdk-core'

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
      kms = Aws::KMS::Client.new(region: region)
      result = decrypt_attributes_recurse(kms, node[top_level_key])
      node.default[top_level_key] = result
  end

  def OpsWorksKMSSecrets.decrypt_attribute(kms, key, ciphertext)

    if ciphertext.nil? then
      return nil
    end

    if ciphertext.empty? then
      return ""
    end

    decoded_base64 = Base64.strict_decode64(ciphertext)
    result = kms.decrypt({ ciphertext_blob: decoded_base64 })
    return result.plaintext
  rescue ArgumentError => e
    puts e.message
    puts "Skipping #{key}; invalid ciphertext"
  rescue Aws::Errors::ServiceError => e
    puts e.message
    puts "Skipping #{key} due to AWS/KMS problem"
  rescue Exception => e
    puts e.message
    puts "Skipping #{key} due to uknown problem"
  end

  def OpsWorksKMSSecrets.encrypt_attribute(kms, kms_key_id, key, plaintext)

    if plaintext.nil? then
      return nil
    end

    if plaintext.empty? then
      return ""
    end

    result = kms.encrypt({ key_id: kms_key_id, plaintext: plaintext })

    return Base64.strict_encode64(result.ciphertext_blob)

  rescue Aws::Errors::ServiceError => e
    puts e.message
    puts "Skipping #{key} due to AWS/KMS problem"
  rescue Exception => e
    puts e.message
    puts "Skipping #{key} due to uknown problem"
  end

  def OpsWorksKMSSecrets.decrypt_attributes_recurse(kms, main_node)

      if main_node.nil? then
        return nil
      elsif main_node.is_a?(String) then
        return main_node
      elsif main_node.is_a?(Hash) then
        new_hash = {}
        main_node.each_pair do | key, value |
          if key.end_with?('_encrypted') then
            plaintext = decrypt_attribute(kms, key, value)
            new_hash[key.sub('_encrypted', '_unencrypted')] = plaintext
            new_hash[key] = value
          else
            result = decrypt_attributes_recurse(kms, value)
            new_hash[key] = result
          end
        end
        return new_hash
      elsif main_node.is_a?(Array) then
        new_array = []
        main_node.each do | element |
          result = decrypt_attributes_recurse(kms, element)
          new_array << result
        end
        return new_array
      else
        return main_node
      end
  end

  def OpsWorksKMSSecrets.encrypt_attributes_recurse(kms, kms_key_id, main_node)

    if main_node.nil? then
      return nil
    elsif main_node.is_a?(Hash) then
      new_hash = {}
      remove_keys = []
      main_node.each_pair do | key, value |
        if key.end_with?('_unencrypted') then
          ciphertext = encrypt_attribute(kms, kms_key_id, key, value)
          if !ciphertext.nil? then
            new_hash[key.sub('_unencrypted', '_encrypted')] = ciphertext
            remove_keys << key
          end
        else
          result = encrypt_attributes_recurse(kms, kms_key_id, value)
          new_hash[key] = result
        end
      end
      main_node.merge!(new_hash)
      main_node.delete_if do | key, value |
        remove_keys.include?(key)
      end
      return main_node
    elsif main_node.is_a?(Array) then
      main_node.map do | element |
        encrypt_attributes_recurse(kms, kms_key_id, element)
      end
    else
      return main_node
    end
  end

  def OpsWorksKMSSecrets.encrypt_json_file(filename, region: 'us-east-1')
    require 'json'

    kms = Aws::KMS::Client.new(region: region)
    main_node = JSON.parse(File.read(filename))

    # expect kms_key_arn at top level of file
    if !main_node.has_key?('kms_key_arn') then
      abort("'kms_key_arn' key missing from top level of file")
    end
    kms_key_id = main_node['kms_key_arn']
    result = encrypt_attributes_recurse(kms, kms_key_id, main_node)
    puts JSON.pretty_generate(result)
  end

  def OpsWorksKMSSecrets.test1
      kms = Aws::KMS::Client.new(region: 'us-east-1')

      node = [
        nil,
        {},
        { "aaaa" => "bbbb" },
        { "aaaa" => { "bbbb" => "cccc" } },
        [],
        [ "fff", "eee"],
        [ "fff", {"eee" => "ggg"} ],
        {
              "fred_key_encrypted" =>  "AQECAHiTAEWO8pFB6IaTC2h+09d7dA2EcEIUW82T8I31+YU3RQAAAGIwYAYJKoZIhvcNAQcGoFMwUQIBADBMBgkqhkiG9w0BBwEwHgYJYIZIAWUDBAEuMBEEDM1ySm4EfICvLE0OhQIBEIAfkw1FAq1N7vWCTC8eqrp4ZPR0WgLHh+OjXwIKjzwpWQ==" },
        { "fred_key_encrypted" =>  nil },
        { "fred_key_encrypted" =>  "dGVzdDsfdsfENCg==" },
        { "fred_key_encrypted" =>  "dGVzdDENCg==" }
      ]
      node.each do |item|
        decrypt_attributes_recurse(kms, item);
      end
  end

  def OpsWorksKMSSecrets.test2
    require 'json'
    filename = 'chef_data_test.json'
    main_node = JSON.parse(File.read(filename))
    kms = Aws::KMS::Client.new(region: 'us-east-1')
    result = decrypt_attributes_recurse(kms, main_node)
    puts JSON.pretty_generate(result)
  end

  def OpsWorksKMSSecrets.test3
      kms = Aws::KMS::Client.new(region: 'us-east-1')
      kms_key_id = 'arn:aws:kms:us-east-1:225162606092:key/c4834e4e-8d53-40f9-aca8-c1596ffa110b'

      node = [
          nil,
          "",
          "test_value"
        ]
      node.each do | item |
        encrypt_attribute(kms, kms_key_id, "test_key", item)
      end

      # try a bogus kms_key_id
      kms_key_id = 'arn:aws:kms:us-east-1:225162606092:key/c4834e4e-8d53-40f9-aca8-c1596ffa110bxxx'
      result = encrypt_attribute(kms, kms_key_id, "test_key", "test_value")
      puts result

  end

  def OpsWorksKMSSecrets.test4
      kms = Aws::KMS::Client.new(region: 'us-east-1')
      kms_key_id = 'arn:aws:kms:us-east-1:225162606092:key/c4834e4e-8d53-40f9-aca8-c1596ffa110b'

      node = [
        nil,
        [],
        [ "a", "b" ],
        [ "a", { "b" => "c" } ],
        {},
        "",
        { "bob" => "fred" },
        { "bob_unencrypted" => "bob_value" }
      ]
      node.each do |item|
        encrypt_attributes_recurse(kms, kms_key_id, item)
      end
  end

  def OpsWorksKMSSecrets.test5
      kms = Aws::KMS::Client.new(region: 'us-east-1')
      kms_key_id = 'arn:aws:kms:us-east-1:225162606092:key/c4834e4e-8d53-40f9-aca8-c1596ffa110b'

      require 'json'
      filename = 'chef_data_test_encryption.json'
      main_node = JSON.parse(File.read(filename))
      result = encrypt_attributes_recurse(kms, kms_key_id, main_node)
      puts JSON.pretty_generate(result)
  end

  def OpsWorksKMSSecrets.test6
      kms = Aws::KMS::Client.new(region: 'us-east-1')
      kms_key_id = 'arn:aws:kms:us-east-1:225162606092:key/c4834e4e-8d53-40f9-aca8-c1596ffa110b'

      require 'json'
      filename = 'chef_data_test_decryption.json'
      main_node = JSON.parse(File.read(filename))
      result = decrypt_attributes_recurse(kms, main_node)
      puts JSON.pretty_generate(result)
  end
end
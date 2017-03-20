# OpsWorksKMSSecrets

This Chef helper library allows recipes to use the KMS tools in [cucloud_ruby](https://github.com/CU-CloudCollab/cucloud_ruby). Specifically it makes it easy to decrypt secrets provided in [OpsWork custom JSON](http://docs.aws.amazon.com/opsworks/latest/userguide/workingstacks-json.html).

## OpsWorksKMSSecrets.decrypt_attributes

Call using `OpsWorksKMSSecrets.decrypt_attributes(region, node, top_level_key)` where:
* `region` is an AWS region (e.g., 'us-east-1')
* `node` is the standard Chef `node` object
* `top_level_key` is the key of a top-level node hash that contains encrypted properties

Example custom JSON data fed into OpsWorks:
```JSON
{
  "duo_config": {
    "integration_key": "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "api_host": "api-xyz.duosecurity.com",
    "secret_key_encrypted": "AQECAHiTAEWO8pFB6IaTC2h+09d7dA2EcEIUW82T8I31+YU3RQAAAIcwgYQGCSqGSIb3DQEHBqB3MHUCAQAwcAYJKoZIhvcNAQcBMB4GCWCGSAFlAwQBLjARBAxpsDSluFm/Vsb2EpYCARCAQ+W6qTyezBwn0ptlfWhOtXwTEnqe71vQomblZair3JiDA/MELYd84UgpBfwU6axKjUiNDknJAK1TgXCMhdKrF12eb5U="
  }
}
```

An example from an OpsWorks recipe ([../recipes/secrets.rb](../recipes/secrets.rb)):
```ruby
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

# After decryption, node['duo_config']['secret_key_decrypted'] will contain the decrypted value of node['duo_config']['secret_key_encrypted'].
```

The decryption step will add the key `secret_key_decrypted` to the `duo_config` hash. I.e., `node['duo_config']['secret_key_decrypted']` will hold the decrypted value at Chef recipe run time.

## Creating Encrypted JSON

You can use simple Ruby code to encrypt JSON that resides in files:
```Ruby
require 'aws-sdk-core'
require 'cucloud'

kms_utils = Cucloud::KmsUtils.new
input = JSON.parse(File.read('mydata.json'))
key_id = input['kms_key_arn']
result = kms_utils.encrypt_struct(input, key_id)
puts JSON.pretty_generate(result)
```

Example `mydata.json` file. You will need to configure your own KMS key and provide the ARN of it in the JSON.

```JSON
{
  "kms_key_arn" : "arn:aws:kms:us-east-1:225162606092:key/c4834e4e-8d53-40f9-aca8-c1596ffa110b",
  "duo_config" : {
    "integration_key" : "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "secret_key_decrypted" : "SOME SECRET KEY",
    "api_host" : "api.example.com"
  },
  "sssd_config" : {
    "ldap_default_authtok_decrypted" : "SECRET PASSWORD",
    "krb5_server" : ["ad19.cornell.edu", "ad20.cornell.edu"]
  }
}
```

The resulting JSON will look something like:
```JSON
{
  "kms_key_arn" : "arn:aws:kms:us-east-1:225162606092:key/c4834e4e-8d53-40f9-aca8-c1596ffa110b",
  "duo_config": {
    "integration_key" : "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "api_host" : "api.example.com",
    "secret_key_encrypted": "AQECAHiTAEWO8pFB6IaTC2h+09d7dA2EcEIUW82T8I31+YU3RQAAAIcwgYQGCSqGSIb3DQEHBqB3MHUCAQAwcAYJKoZIhvcNAQcBMB4GCWCGSAFlAwQBLjARBAxpsDSluFm/Vsb2EpYCARCAQ+W6qTyezBwn0ptlfWhOtXwTEnqe71vQomblZair3JiDA/MELYd84UgpBfwU6axKjUiNDknJAK1TgXCMhdKrF12eb5U="
  },
  "sssd_config": {
    "krb5_server": [
      "ad19.cornell.edu",
      "ad20.cornell.edu"
    ],
    "ldap_default_authtok_encrypted": "AQECAHiTAEWO8pFB6IaTC2h+09d7dA2EcEIUW82T8I31+YU3RQAAAGYwZAYJKoZIhvcNAQcGoFcwVQIBADBQBgkqhkiG9w0BBwEwHgYJYIZIAWUDBAEuMBEEDOVp+RPdZTfE7pXXJgIBEIAjr69VIu8eZjd6DEL4yJ/AW5ajnLU6VgqQWhhsYIRUC2SEU0c="
  }
}
```



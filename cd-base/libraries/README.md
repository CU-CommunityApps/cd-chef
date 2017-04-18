# Notes

## Manually encrypting data for OpsWorks custom JSON

1. Put plaintext in file data.txt.
2. Encrypt:
  ```
  aws kms encrypt --key-id 9270d36b-9bc7-4945-aba2-d2f017d2051a --plaintext fileb://data.txt --output text --query CiphertextBlob > data.txt.encrypted
  ```
2. Copy base64 encoded encrypted data out of `data.txt.encrypted`. Leave it as base64 encoded when you include it as custom JSON attribute value.
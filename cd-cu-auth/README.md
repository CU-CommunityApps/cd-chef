# cd-cu-auth

## Cookbook Description

Configures Ubuntu 16 LTS OpsWorks EC2 instances with users and groups from Cornell AD. Uses kerberos, sssd, and Duo for authentication and access control. It can work in conjunction with [cd-efs cookbook]()../cd-efs) to mount EFS volumes and gives access to them in sftp configuration, based on Cornell AD group. Access to the system is allowed only via SFTP by users in specified AD Groups.

## To Do

* Change `sssd.conf` to use ad9.cornell.edu and ad10.cornell.edu for `krb5_server` property. These servers reside in an AWS VPC that must be peered to the VPC where these OpsWorks instances are deployed. For testing, we use the ad19.cornell.edu and ad20.cornell.edu servers, which reside in on-campus 10-space, instead.
* Determine if non-root users on an OpsWorks/Chef instance can get access to the converged node attributes. Secrets are stored there.
* Move the KMS-based secret encryption/decryption out of the [cd-cu-auth_helper.rb library](libraries/cd-cu-auth_helper.rb) into one of our main AWS Ruby repos.
* Create spec tests for recipes.
* Check if cd-cu-auth users mush have "IsUnixEnabled?" in Cornell AD.
* Do something useful with connection logs. Do we need/want to configurate and expose detailed SFTP logs?

### Feedback from Cornell IdM for Review and Potential Action

* You could add the AWS AD DCs to your krb5.conf, maybe, to avoid having to put them into the sssd.conf file? (I'm not sure how that works - I thought maybe you had to add them explicitly because they weren't in the krb5.conf).
* It's not clear to me whether you are using ldap authentication, or kerberos authentication, or both? It seems like you ought to be able to do one or the other, right?
* In [sssd.conf.erb](templates/sssd/sssd.conf.erb)
  * The `ldap_user_gid_number` and `override_gid` do not seem to both be necessary.
  * Not sure about choice of "cn" as the username. It's gotta be almost always right, but I know there are some conflicts there. (e.g., AD20). Use sAMAccountName instead?
  * Also, I don't quite grok the case-sensitivity comments on there, but I know that AD is not case sensitive. So "jes59" can log in as "jes59" or "Jes59" or "JES59" or whatever. Will this cause problems? Maybe there should be something in there that forces lowercase, to avoid those issues?

## Caveats

* It will probably be infinitely useful if the SFTP clients used for connecting can be configured to set file/dir permissions after files are uploaded. This will solve problems where other users accessing the same directories do not have write permissions (via group permissions) to manipulate files. SFTP users are configured to use `umask 002` which, on an uploaded file, will keep any group permissions set on a local file. This umask helps in some cases, but only when the file local to SFTP users have group permissions set appropriately.

## Potential Enhancements

* Setup ssh sysadmin access to the instance, based on a Cornell AD group and using the Cornell AD and Duo to authenticate the sysadmin users.

## Tests

### Manual Tests

* Ensure that valid AD users (other than "ubuntu") cannot ssh into the system. Such users will be asked for their password and for DUO factor, but they should get a message that "This service allows sftp connections only."
* Ensure that "ubuntu" can ssh into system using the private key specified at EC2 instance launch.
* Ensure that valid AD users, who aren't included in one of the AD groups configured for EFS access, cannot ssh or sftp. There "rejection" will simply look like they repeatedly entered bad passwords. I.e.:
```
$ sftp mna1@10.92.77.201
Password:
Password:
Password:
Received disconnect from 10.92.77.201: 2: Too many authentication failures
Disconnected from 10.92.77.201
Connection closed
```

## Configuration

### "Static" AWS Resources

These AWS resources are required so that the OpsWorks configuration can provided required functionality.

* IAM Roles
  * `efs-connect-opworks-instance-profile` - an instance profile/role to hold privileges required by ef-connect EC2 instances. It is empty at this time.
* EC2 Security Groups
  * `efs-connect-opsworks-sg` -- configure user access to the efs-connect OpsWorks instances (i.e., open SSH (port 22) from 10.0.0.0/8).
* VPC Resources
  * private subnets - EC2 instances implementing this configuration should be in private subnets in the Cornell standard VPC
* KMS keys
  * A KMS key is used for encrypting/decrypting secrets passed into recipes via OpsWorks custom JSON. The `shib-admin` role should be named as a key administrator for the key, and the `efs-connect-opworks-instance-profile` role should be listed as a key user, along with possibly `shib-admin` or other users/roles that will be decrypting/encrypting secrets during configuration and testing.
    * In cloud-devops account, for efs-connect
      * arn:aws:kms:us-east-1:095493758574:key/5e4c428f-6446-4004-b0ee-0a19710b110f
    * In cs-sanbox account, pea-efs-stack
      * arn:aws:kms:us-east-1:225162606092:key/c4834e4e-8d53-40f9-aca8-c1596ffa110b


## Recipes

### Default Recipe

The `default` recipe in the cookbook simply runs the following recipes:
* `kerberos`
* `sssd`
* `duo`
* `sftp`

The `efs` recipe should be run separately because of problems noted above.

### kerberos Recipe

The Kerberos recipe installs and configures Kerberos, according to the [krb5 cookbook](https://supermarket.chef.io/cookbooks/krb5). However, it dispenses with attribute-level configuration, and instead just installs the Cornell standard [krb5.conf file](files/kerberos/krb5.conf).

### sssd Recipe

This recipe ensures that `sssd` is installed, configures it with [sssd.conf from a template](templates/sssd/sssd.conf.erb) and [nsswitch.conf](files/sssd/nsswitch.conf), and restarts `sssd`. These configuration files are derived from files provided by Cornell Identity Management.

### duo Recipe

This configuration is based on [instructions from Duo](https://duo.com/docs/duounix).

The recipe does the following:
* adds the Dou repo to the list of Ubuntu repos
* installs the `duo-unix` library
* replaces `pam.d/common-auth` with a configuration that ensures duo is used
* configures integration and secret keys for the Duo module via a [template for pam_duo.conf](templates/duo/pam_duo.conf.erb). The keys are provided from [Cornell Duo service](http://www.it.cornell.edu/services/twostep/howto/addtoservice.cfm) upon request.

#### duo Recipe Custom JSON

The `duo` recipe relies on OpsWorks custom JSON for configuration.

**Example**

```JSON
{
  "duo_config": {
    "integration_key": "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "api_host": "api-xyz.duosecurity.com",
    "secret_key_encrypted": "AQECAHiTAEWO8pFB6IaTC2h+09d7dA2EcEIUW82T8I31+YU3RQAAAIcwgYQGCSqGSIb3DQEHBqB3MHUCAQAwcAYJKoZIhvcNAQcBMB4GCWCGSAFlAwQBLjARBAxpsDSluFm/Vsb2EpYCARCAQ+W6qTyezBwn0ptlfWhOtXwTEnqe71vQomblZair3JiDA/MELYd84UgpBfwU6axKjUiNDknJAK1TgXCMhdKrF12eb5U="
  }
}
```

### sftp Recipe

This recipe is primarily configured using the [sftp.rb attributes file](attributes/sftp.rb). The configuration captured in that file is derived from the default configuration of `ssh_conf` and `sshd_conf` in Ubuntu 16.04 as deployed by OpsWorks/EC2. From that configuration, attributes are overridden in the [sftp.rb recipe file itself](recipes/sftp.rb).

The purpose of the configuration is to:
* continue to allow the usual ssh access to EC2 instances by instance administrators (i.e., user `ubuntu`)
* setup sftp access driven by layer custom JSON

Features of sftp configuration:
* users in AD groups named in the custom JSON should be allowed to access the system only via sftp
* once connected, such users are `chroot`ed to `/mnt`. This means they will see only the directories configured in the custom JSON.
* such users are prevented from using the system for X11 and TCP forwarding
* such users must authenticate using passwords, and because of the sssd/pam configuration, they will also be required to utilize Duo for MFA.

Notes:
* It is possible configure a umask for sftp users. See comments in [sftp.rb](recipes/sftp.rb) but that doesn't solve the problem users will run into where files they create in the /mnt subdirectories don't by default give other users in the same group write permissions.
* The `Match` directive is used to configure access for users belonging to the AD groups from the layer custom JSON. If a user belongs to multiple configured groups, the last matched group has precedence. However, since the configuration is the same for all `Matches`, this doesn't have any functional affect.

#### sftp Recipe Custom JSON

The `sftp` recipe relies on OpsWorks custom JSON for configuration.

**Example**

```JSON
{
  "sssd_config": {
    "ldap_default_bind_dn": "CN=cit-pea1-hid,OU=cloud-devops,OU=Cloudification,OU=HoldingIDs,OU=IDs,OU=CIT-ENT,OU=DelegatedObjects,DC=cornell,DC=edu",
    "krb5_server": [
      "ad19.cornell.edu",
      "ad20.cornell.edu"
    ],
    "ldap_uri": "ldaps://ad19.cornell.edu",
    "ldap_backup_uri": "ldaps://ad20.cornell.edu",
    "ldap_default_authtok_encrypted": "AQECAHiTAEWO8pFB6IaTC2h+09d7dA2EcEIUW82T8I31+YU3RQAAAGYwZAYJKoZIhvcNAQcGoFcwVQIBADBQBgkqhkiG9w0BBwEwHgYJYIZIAWUDBAEuMBEEDOVp+RPdZTfE7pXXJgIBEIAjr69VIu8eZjd6DEL4yJ/AW5ajnLU6VgqQWhhsYIRUC2SEU0c="
  }
}
```

## Secrets

Secrets required by this configuration:
* `sssd` Recipe - the password for the bind ID credentials used in `sssd.conf`
* `duo` Recipe - the secret key used by Duo integration in `pam_duo.conf`

This cookbook includes a [cookbook helper library, cd-cu-auth_helper.rb](libraries/cd-cu-auth_helper.rb), that contains Ruby functions that decrypt attributes found in the OpsWorks custom JSON. This Ruby code uses AWS KMS for encrypting/decrypting secrets.

Custom JSON of the form:
```JSON
{
  "myconfig" : {
    "key1" : "value1",
    "key2_encrypted" : "THE ENCRYPTED VALUE FOR 'value2' IN STRICT BASE64 ENCODING"
  }
}
```
is decrypted to:
```JSON
{
  "myconfig" : {
    "key1" : "value1",
    "key2_encrypted" : "THE ENCRYPTED VALUE FOR 'value2' IN STRICT BASE64 ENCODING",
    "key2_unencrypted" : "value2"
  }
}
```

[cd-cu-auth_helper.rb](libraries/cd-cu-auth_helper.rb) also contains functions to encrypt values of keys with suffix "-unecrypted" in JSON files.

## Notes

### Kerberos Notes

* To see if kerberos is correctly configured to use Cornell Kerberos:

  ```
  $ kinit pea1 # This should require you to enter pea1's Cornell netId password.
  $ klist # This will list existing kerberos tickets
  ```

  See also http://web.mit.edu/Kerberos/krb5-1.13/doc/user/user_commands/index.html

* Using a keytab (/etc/krb5.keytab):

  ````
  # klist -k /etc/krb5.keytab
  Keytab name: FILE:/etc/krb5.keytab
  KVNO Principal
  ---- --------------------------------------------------------------------------
   3 pea1.dev@CIT.CORNELL.EDU
   3 pea1.dev@CIT.CORNELL.EDU
   3 pea1.dev@CIT.CORNELL.EDU
   3 pea1.dev@CIT.CORNELL.EDU

  # kinit -k pea1.dev
  root@base-layer1:~# klist
  Ticket cache: FILE:/tmp/krb5cc_0
  Default principal: pea1.dev@CIT.CORNELL.EDU

  Valid starting       Expires              Service principal
  11/08/2016 13:12:17  11/08/2016 23:12:17  krbtgt/CIT.CORNELL.EDU@CIT.CORNELL.EDU
	renew until 11/09/2016 13:12:16
  ````

  **Note that a keytab is not required for the recipes in this cookbook.**

### LDAP

#### Search Examples

* A query that doesn't require a bind ID.
```
ldapsearch -b "ou=People,o=Cornell University, c=US" -H ldaps://test.directory.cornell.edu:636 -x -L uid=pea1
```

* This query, using a bind ID, works. Password for bind ID is required.
```
ldapsearch -x -H ldaps://ad19.cornell.edu:636 -b "dc=cornell,dc=edu" -D "CN=cit-pea1-hid,OU=cloud-devops,OU=Cloudification,OU=HoldingIDs,OU=IDs,OU=CIT-ENT,OU=DelegatedObjects,DC=cornell,DC=edu" -w PASSWORD -L uid=pea1
```

### SSSD

```
$ systemctl restart sssd

# install sss_cache utility
$ apt-get install sssd-tools

# clear the cache that holds information about users/groups looked up from Cornell AD
$ sss_cache -E
```

## Resources

[SSH Cookbook](https://supermarket.chef.io/cookbooks/openssh)
[KRB5 Cookbook](https://supermarket.chef.io/cookbooks/krb5)





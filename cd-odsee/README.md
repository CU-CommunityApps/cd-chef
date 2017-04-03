# cd-odsee

## Cookbook Description

Install and configure ODSEE for Cornell IDM. New instances are bootstrapped by importing ldif data dumps from the existing servers.

## To Do

* Install and configure tomcat. We might want to install tomcat on a standalone server. Chris M thought that would/might be ok. See cd-odsee::tomcat recipe for a start at that.
  * Note that some of the shell scripts in the scripts directory also interact with the Tomcat instance (i.e., stop, start). If we move tomcat to a separate instance, then those would have to be examined more closely.
* Add default passwords to attributes/default.rb (e.g., "agent_password_decrypted").
* Pull real passwords from (OpsWorks) encrypted custom JSON or pull from S3 file(s).
* Add a recipe to configure a Route53 record for the host. This is in expectation that we will be doing _something_ with Route53 for the real case. (https://supermarket.chef.io/cookbooks/route53)

* Work with Chris McLain to:
  * Work out DNS, CNAMES, etc. Hopefully use Route53 as much as possible for automated records. The ideal would be to use an ELB as part of the OpsWorks layer configuration. Then we wouldn't have to manage DNS records for hostnames individually and expect some other mechanism to hide (and utilize) the individual instances.
  * The Security group shown as a screenshot in the JIRA ticket is not configured correctly. Chris says that he was fiddling with it because he was having problems. The real SG should be locked down more. The SG used in the sandbox odsee-dev OpsWorks stack is not configured at all.
  * They will probably want to use real certificates for test, prod. So we will need to figure that out with them. There seems to be a lot of odsee commands to manage certificates.
  * We need to get info from Chris how to configure eduperson and cornelleduperson types in these new servers. The ldif data doesn't load correctly now because the server don't know those data types. The import_data recipe runs without error now, but ends up ignoring most of the data because of this issue.
  * Figure out which scripts (in the scripts dir) the IDM uses to manage these servers. Expose those scripts via recipes.
  * Configure syncing with other directories. Confirm that syncing works.

## Issues

* As of 4/3/2017, the `ads-create` step in `odsee_server` never seems to work the first time around. However, the second time the recpipe is run, that step completes just fine. See below.
  ```
  ================================================================================
  Error executing action `run` on resource 'execute[ads-create]'
  ================================================================================

  Mixlib::ShellOut::ShellCommandFailed
  ------------------------------------
  Expected process to exit with [0], but received '125'
  ---- Begin output of bin/dsccsetup ads-create -w /tmp/admin_password.txt ----
  STDOUT: Creating DSCC registry...
  null
  Unexpected error
  Sofware installation is probably incomplete or corrupted
  STDERR:
  ---- End output of bin/dsccsetup ads-create -w /tmp/admin_password.txt ----
  Ran bin/dsccsetup ads-create -w /tmp/admin_password.txt returned 125

  Resource Declaration:
  ---------------------
  # In /var/chef/runs/65dcd210-ed4b-422a-9d39-0ce7012ac3c7/local-mode-cache/cache/cookbooks/cd-odsee/recipes/odsee_server.rb

  111: execute 'ads-create' do
  112:   command 'bin/dsccsetup ads-create -w '+admin_password_file
  113:   # not_if install_path+'/bin/dsccsetup status | grep "DSCC Registry has been created"'
  114:   cwd install_path
  115: end
  116:

  Compiled Resource:
  ------------------
  # Declared in /var/chef/runs/65dcd210-ed4b-422a-9d39-0ce7012ac3c7/local-mode-cache/cache/cookbooks/cd-odsee/recipes/odsee_server.rb:111:in `from_file'

  execute("ads-create") do
  action [:run]
  retries 0
  retry_delay 2
  default_guard_interpreter :execute
  command "bin/dsccsetup ads-create -w /tmp/admin_password.txt"
  backup 5
  cwd "/app/ldap/ds-7/dsee7"
  returns 0
  declared_type :execute
  cookbook_name "cd-odsee"
  recipe_name "odsee_server"
  end

  Platform:
  ---------
  x86_64-linux

  [2017-04-03T11:09:48-04:00] INFO: Running queued delayed notifications before re-raising exception
  [2017-04-03T11:09:48-04:00] ERROR: Running exception handlers
  [2017-04-03T11:09:48-04:00] ERROR: Exception handlers complete
  [2017-04-03T11:09:48-04:00] FATAL: Stacktrace dumped to /var/chef/runs/65dcd210-ed4b-422a-9d39-0ce7012ac3c7/local-mode-cache/cache/chef-stacktrace.out
  [2017-04-03T11:09:48-04:00] FATAL: Please provide the contents of the stacktrace.out file if you file a bug report
  [2017-04-03T11:09:48-04:00] ERROR: execute[ads-create] (cd-odsee::odsee_server line 111) had an error: Mixlib::ShellOut::ShellCommandFailed: Expected process to exit with [0], but received '125'
  ---- Begin output of bin/dsccsetup ads-create -w /tmp/admin_password.txt ----
  STDOUT: Creating DSCC registry...
  null
  Unexpected error
  Sofware installation is probably incomplete or corrupted
  STDERR:
  ---- End output of bin/dsccsetup ads-create -w /tmp/admin_password.txt ----
  Ran bin/dsccsetup ads-create -w /tmp/admin_password.txt returned 125
  [2017-04-03T11:09:49-04:00] FATAL: Chef::Exceptions::ChildConvergeError: Chef run process exited unsuccessfully (exit code 1)
  ```

## Notes

* Use plain "1", "2", "3" as the hostname when you add instances to the stack. A prefix (of the layer name) will be added when the instances are given an EC2 name.
* Importing the data as given (e.g. ldif file) is the normal way that a new server is bootstrapped.
* Launching instances now on a public subnet, assuming that instances need to be publicly assessable. They may not need to be, depending on if ELB or other round-robin access scheme is used (need to meet with customer about this).

## Configuration

### OpsWorks Layer Custom JSON

```JSON
{
	"route53": {
		"zone_id": "Z1K86BI6YYEXQK",
    "subdomain": "cs.cucloud.net"
	}
}
```
### "Static" AWS Resources

Resources required by the OpsWorks layer.

* EC2 key pairs
  * We are using key pairs now for ssh access, but probably won't need them long-term, since the baked in OpsWorks user management can be used instead.
* S3 buckets
  * cu-cs-odsee
    * Contains credentials, scripts, and other artifacts for installing and configuring ODSEE for Cornell IDM
* IAM Instance Profile
  * [odsee-opsworks-role](https://console.aws.amazon.com/iam/home?region=us-east-1#/roles/odsee-opsworks-role)
    * Managed policy: ec2-create-tag - allows cd-base::instance_tags to create custom tags
    * Inline policy: odsee-s3-bucket-access R/W the odsee configuration bucket
      ```
      {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Sid": "Stmt1490805225000",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::cu-cs-odsee",
                "arn:aws:s3:::cu-cs-odsee/*"
            ]
          }
        ]
      }
      ```
    * Inline policy: manage-route53-records - allow management of DNS records
      ```
      {
        "Version": "2012-10-17",
        "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "route53:ListHostedZones"
              ],
              "Resource": "*"
          },
          {
              "Effect": "Allow",
              "Action": [
                  "route53:GetHostedZone"
              ],
              "Resource": "arn:aws:route53:::hostedzone/Z1K86BI6YYEXQK"
          },
          {
              "Effect": "Allow",
              "Action": [
                  "route53:ListResourceRecordSets"
              ],
              "Resource": "arn:aws:route53:::hostedzone/Z1K86BI6YYEXQK"
          },
          {
              "Effect": "Allow",
              "Action": [
                  "route53:ChangeResourceRecordSets"
              ],
              "Resource": "arn:aws:route53:::hostedzone/Z1K86BI6YYEXQK"
          }
        ]
      }
      ```
* Security Groups
  * [odsee-security-group](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#SecurityGroups:search=sg-7329a30c;vpcId=vpc-71070114;sort=groupId)
    * This is the group that will be used to provide real access controls to ODSEE configuration.
  * [AWS-OpsWorks-Default-Server](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#SecurityGroups:search=sg-2e766348;sort=groupId)
    * Not sure if this group is required. Probably not. Need to test. It was added by default to the layer configuration.


## Recipes

* setup_credentials - setup passwords in files to use during install
* odsee_server - install and configure the ODSEE server
* import_data - import data into the ODSEE server
* cleanup - remove credentials files no longer needed
* start_server - just start the ODSEE server (using the Makefile that IDM has used in the past)
* tomcat - install and configure tomcat
* default
  # include_recipe "cd-odsee::setup_credentials"
  # include_recipe "cd-odsee::odsee_server"
  # include_recipe "cd-odsee::import_data"
  # include_recipe "cd-odsee::cleanup" -- COMMENTED OUT OF DEFAULT FOR NOW

## Managing the Cookbook Repo

### Cloning the Repo

```
git clone https://github.com/CU-CommunityApps/cd-chef.git

git submodule update --init --recursive
```

### Adding a submodule

```
git submodule add https://github.com/chef-cookbooks/route53.git
git commit -m "add Route53 cookbook as a submodule"
```

## Running OpsWorks commands on an instance

```
sudo opsworks-agent-cli run_command update_custom_cookbooks
sudo opsworks-agent-cli run_command execute_recipes recipe["cd-odsee"]
```


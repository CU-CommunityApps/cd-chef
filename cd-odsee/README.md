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
  * Work out DNS, CNAMES, etc. Hopefully use Route53 as much as possible for automated records.
  * The Security group shown as a screenshot in the JIRA ticket is not configured correctly. Chris says that he was fiddling with it because he was having problems. The real SG should be locked down more. The SG used in the sandbox odsee-dev OpsWorks stack is not configured at all.
  * They will probably want to use real certificates for test, prod. So we will need to figure that out with them. There seems to be a lot of odsee commands to manage certificates.
  * We need to get info from Chris how to configure eduperson and cornelleduperson types in these new servers. The ldif data doesn't load correctly now because the server don't know those data types. The import_data recipe runs without error now, but ends up ignoring most of the data because of this issue.
  * Figure out which scripts (in the scripts dir) the IDM uses to manage these servers. Expose those scripts via recipes.
  * Configure syncing with other directories. Confirm that syncing works.

## Issues


## Notes

* Use plain "1", "2", "3" as the hostname when you add instances to the stack. A prefix (of the layer name) will be added when the instances are given an EC2 name.
* Importing the data as given (e.g. ldif file) is the normal way that a new server is bootstrapped.

## Configuration

### OpsWorks Layer Custom JSON

```
{
	"route53": {
		"zone_id": "Z1K86BI6YYEXQK"
	}
}
```

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

### "Static" AWS Resources

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




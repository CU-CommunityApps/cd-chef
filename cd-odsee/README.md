# cd-odsee

## Cookbook Description

## To Do

* Install and configure tomcat. We might want to install tomcat on a standalone server. Chris M thought that would/might be ok.
* Work out DNS, CNAMES, etc. Hopefully use Route53 as much as possible for automated records.
* Add default passwords to attributes/default.rb (e.g., "agent_password_decrypted") or pull from S3 file(s).
* They will probably want to use real certificates for test, prod. So we will need to figure that out with them. There seems to be a lot of odsee commands to manage certificates.
* The Security group shown as a screenshot in the JIRA ticket is not configured correctly. Chris says that he was fiddling with it because he was having problems. The real SG should be locked down more.

## Notes

* Importing the data as given is the normal way that a new server is bootstrapped.

## Configuration

### Cloning the Repo

```
git clone https://github.com/CU-CommunityApps/cd-chef.git

git submodule update --init --recursive
```

### "Static" AWS Resources

## Recipes

### Default Recipe



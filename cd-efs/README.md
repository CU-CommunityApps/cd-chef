# cd-efs

## Cookbook Description

Works in conjunction with [cd-cu-auth](../cd-cu-auth), which configures Ubuntu 16 LTS OPsWorks EC2 instances with users and groups from Cornell AD. [cd-cu-auth](../cd-cu-auth) uses kerberos, sssd, and Duo for authentication and access control. This cookbook, [cd-efs](../cd-efs), mounts EFS volumes and configures them for access using directory group permissions.

## To Do

* Fix nagging issue with `cd-efs::efs` recipe where the recipe fails because the system doesn't recognize that AD groups (used in directory group assignment) are real. Work around this issue by running `cd-cu-auth::default` and then running `cd-efs::efs` separately.
* Create spec tests for recipes.

## Configuration

### "Static" AWS Resources

These AWS resources are required so that the OpsWorks configuration can provided required functionality.

* EC2 Security Groups
  * EFS mount target security group(s)
    * one security group for each EFS volume (.e.g., efs-mountTargetSecurityGroup-XX)
    * this allows access by the EC2 instance to that EFS volume
* VPC Resources
  * private subnets - EC2 instances implementing this configuration should be in private subnets in the Cornell standard VPC
* EFS Resources
  * EFS volumes to which access is to be provisioned
  * The OpsWorks layer/instances does not need EFS for its own use.

### High Availability Considerations

This OpsWorks stack provides user access to EFS volumes. The assumption is that those volumes have mount targets in both private subnets of a Cornell standard VPC. Therefore, for best availability, our configuration should run an EC2 instance in each of the private subnets. This provides availability in case one of the AZs is down.

### On-System File Structure and Permissions

```
mnt
├── ad_group_dir_name_1
│   ├── efs_file_system_a
│   └── efs_file_system_b
└── ad_group_dir_name_2
    └── efs_file_system_c
```

* `mnt`
  * **owner:group** root:root
  * **permissions** 0755
  * `ad_group_dir_name_N`
    * **owner:group** root:ad_group_name
    * **permissions** 0750
    * This directory level resides on the local file system and serves to block access to  users that do not belong to the given AD group. The local system enforces these permissions.
    * `efs_file_system_X`
      * **owner:group** root:users (0:100)
      * **permissions** 0770
      * This is the actual directory where the EFS volume is mounted. The odd group for the directory is required because EFS cannot properly enforce/check group membership of users. We rely on the parent directory permissions to ensure proper access control to this directory.

[sssd](../cd-cu-auth/recipes/sssd.rb) is configured to set the primary group for each user to 100, which is the `users` group on the system. Checking actual group membership at the `ad_group_dir_name_N` level is possible because the local system has access to the entire list of Cornell AD groups to which a user belongs. However, EFS cannot perform similar group membership checks because it suffers from the "16 Group Limit Problem" like other NFS servers (see http://nfsworld.blogspot.com/2005/03/whats-deal-on-16-group-id-limitation.html). However, EFS does always get the primary group for users and so here we override the primary group that normally comes from Cornell AD.

Note also that in an ideal world, we would like to use real AD groups along with the setgid bit for the mounted EFS volumes. This would make it easier for SFTP users to manage shared files. However, EFS does not support setgid bit. See [EFS documentation](http://docs.aws.amazon.com/efs/latest/ug/nfs4-unsupported-features.html).

## Recipes

### Default Recipe

The `default` recipe in the cookbook simply runs the following recipes:
* `efs`

### efs Recipe

The `efs` recipe creates the directory structure and mounts EFS volumes as described above, driven by OpsWorks layer custom JSON. It relies on the `aws_opsworks_instance` and the `aws_opsworks_stack` Chef databags to retrieve availability zone and region information.

In addition to mounting the EFS volumes initially, it updates `/etc/fstab` to ensure the volumes are re-mounted after reboots.

#### efs Recipe Custom JSON

The `efs` recipe relies on OpsWorks custom JSON for configuration.

**Example**

```JSON
{
  "filesystems" : [
    {
      "ad_group" : "CIT-225162606092-admin",
      "ad_group_dir_name" : "cu-cs-sanbox",
      "mounts" : [
        { "efs_id" : "fs-2c538265",
          "mount_dir_name" : "pea1-efs-test-CC"
        },
        { "efs_id" : "fs-2453826d",
          "mount_dir_name" : "pea1-efs-test-DD"
        }
      ]
    },
    {
      "ad_group" : "CIT-095493758574-admin",
      "ad_group_dir_name" : "cu-cloud-devops",
      "mounts" : [
        {
          "efs_id" : "fs-ffb767b6",
          "mount_dir_name" : "pea1-efs-test-EE"
        }
      ]
    },
    {
      "ad_group" : "CIT-243238723662-admin",
      "ad_group_dir_name" : "cu-acadtech",
      "mounts" : [
        {
          "efs_id" : "fs-88b767c1",
          "mount_dir_name" : "pea1-efs-test-FF"
        }
      ]
    }
  ]
}
```

## Notes


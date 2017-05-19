# cd-efs

## Cookbook Description

Works in conjunction with [cd-cu-auth](../cd-cu-auth), which configures Ubuntu 16 LTS OPsWorks EC2 instances with users and groups from Cornell AD. [cd-cu-auth](../cd-cu-auth) uses kerberos, sssd, and Duo for authentication and access control. This cookbook, [cd-efs](../cd-efs), mounts EFS volumes and configures them for access using directory group permissions.

`cd-efs::s3backup` recipe configures a cron job to backup mounted EFS volumes to s3 using [s3cmd](http://s3tools.org/s3cmd). This tools is used instead of native AWS `s3` or `s3api` CLI interface since handles:
- zero length files
- maintains uid, guid, and other file metadata (e.g., create time)

## To Do

* Fix nagging issue with `cd-efs::efs` recipe where the recipe fails because the system doesn't recognize that AD groups (used in directory group assignment) are real. Work around this issue by configuring `cd-cu-auth::default` as an OpsWorks Setup recipe and `cd-efs::efs` as an OpsWorks Configure recipe.
* Create spec tests for recipes.
* Use simplified method for mounting EFS volumes: https://aws.amazon.com/about-aws/whats-new/2016/12/simplified-mounting-of-amazon-efs-file-systems/

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
* S3 Bucket(s)
  * the instance profile is required to have access to an S3 bucket for backups
  * Specific recommendations about bucket lifecycle policies and version will be forthcoming.
* Instance Profile
  * The instance profile used by the OpsWorks instances that wish to backup EFS to S3, must have a policy to allow that. E.g.
  ```JSON
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "Stmt1466096728000",
              "Effect": "Allow",
              "Action": [
                  "s3:ListBucket"
              ],
              "Resource": [
                  "arn:aws:s3:::cu-cloud-devops-boomi"
              ]
          },
          {
              "Sid": "Stmt1466096728001",
              "Effect": "Allow",
              "Action": [
                  "s3:*"
              ],
              "Resource": [
                  "arn:aws:s3:::cu-cloud-devops-boomi/*"
              ]
          }
      ]
  }
  ```

### High Availability Considerations

This OpsWorks stack provides user access to EFS volumes. The assumption is that those volumes have mount targets in both private subnets of a Cornell standard VPC. Therefore, for best availability, our configuration should run an EC2 instance in each of the private subnets. This provides availability in case one of the AZs is down. However, you won't be able to seamlessly load balance among the instances using and ELB because stickiness is required and not possible with SSH traffic.

Also note that the `cd-efs::s3backup` recipe should not be configured for an OpsWorks layer that has more than one running instance. Otherwise, EFS volumes will be backed-up once for each instance.

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

### s3backup Recipe

The `s3backup` recipe assumes that EFS file system is already mounted (by some other recipe, like `efs`). Its job is to setup a cron job that uses a script to accomplish EFS backups.

#### Example Backup Timings

These examples (Case A, Case B) ran on the same EC2 t2.micro instance sequentially. CPU usage spiked to 15-20% occasionally during the backups (initial and later sync) but was generally 5-10% sustained. These backups did not max out any monitoring metric. It did not significantly draw down CPU credit balance. None of the EFS volume metrics maxed out or bottomed out during the initial backup or the later syncs.

| Case | Type | Time (minutes) | # Files Examined | Total File Bytes Transferred |
| --- | --- | ---: | ---: | --- |
| A | initial sync | 141 | 45,925 | 12.6 GB |
| A | subsequent sync  | 16  | 45,926 | 11.5 MB |
| B | initial sync | 145 | 46,583 | 15.2 GB |
| B | subsequent sync  | 24  | 46,584 | 17.1 MB |

#### s3backup Recipe Custom JSON

The custom JSON is separate from the custom JSON for the `efs` recipe. This is so that this recipe can be used without necessaryily having the EFS volumes mounted by the `efs` recipe.

The sample below will backup the EFS volume mounted at `/mnt/ca-integrations/boomi-test` to `s3://cu-cloud-devops-boomi/efs-backups/fs-ab74bde2`.

A log of the backup is stored at `<mount_path>/efs-backup.log`, and backed-up to S3 in a separate step.

A shorter cron log is created on the instance at `/var/log/efs-backup.log`.

```json
{
  "efs_mounts": [
    {
      "mount_path": "/mnt/ca-integrations/boomi-test",
      "efs_id": "fs-ab74bde2",
      "backup_s3bucket_name": "cu-cloud-devops-boomi",
      "backup_s3bucket_prefix": "efs-backups",
      "backup_dry_run": true,
      "backup_verbose": true
    }
  ]
}
```

#### s3backup Recipe IAM Privileges

The following policy could be attached to an efs-connect instance role to give the instance access to a target S3 bucket.

```json
 {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "arn:aws:s3:::*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::cu-cloud-devops-boomi"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::cu-cloud-devops-boomi/*"
            ]
        }
    ]
}
```


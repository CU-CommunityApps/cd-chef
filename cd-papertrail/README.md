# cd-papertrail

A cookbook to setup remote_syslog2 and send logs to Papertrail.

## Custom JSON

You need to configure the exact Papertrail target using OpsWorks custom JSON.

```json
{
  "remote_syslog2" : {
    "config" : {
      "files" : [
        "/var/chef/runs/**/chef.log",
        "/var/log/sssd/*.log",
        "/var/log/syslog",
        "/var/log/auth.log"
      ],
      "exclude_files" : [],
      "exclude_patterns" : [],
      "destination" : {
        "host" : "logsXXX.papertrailapp.com",
        "port" : 12345,
        "protocol" : "tls"
      }
    }
  }
}
```

# Notes

Notes about research on configuring Duo integration into PAM

## Required Pakacges

* libssl-dev
* libpam-dev

## Duo Integration

* https://duo.com/docs/duounix
* https://wiki.umms.med.umich.edu/display/ET/4.+to+use+PAM+setup+for+LDAP+with+DUO+on+Linux+box

## PAM configuration

### Config Test 1

Change /etc/pam.d/common-auth:
```
# ORIGINAL auth  [success=1 default=ignore]      pam_unix.so nullok_secure
auth    requisite       pam_unix.so nullok_secure
auth    [success=1 default=ignore]      /lib64/security/pam_duo.so
```
## Config Test 2

* The config below:
  * seems to work for 'pea1' user authenticated against kerberos, and invoking duo.
  * allows 'test1' to login, but does not invoke duo

Change /etc/pam.d/common-auth:
```
# here are the per-package modules (the "Primary" block)
#auth   [success=2 default=ignore]      pam_krb5.so minimum_uid=1000
#auth   [success=1 default=ignore]      pam_unix.so nullok_secure try_first_pass

auth    sufficient                      pam_unix.so
auth    requisite                       pam_krb5.so minimum_uid=1000 try_first_pass
auth    [success=1 default=ignore]      /lib64/security/pam_duo.so
```

## Config Test 3 - Seems to Work

Change /etc/pam.d/common-auth:
```
auth    [success=ok default=1]  pam_krb5.so minimum_uid=1000
auth    [success=3 default=ignore]      /lib64/security/pam_duo.so
auth    [success=ok default=1]  pam_unix.so nullok_secure try_first_pass
auth    [success=1 default=ignore]      /lib64/security/pam_duo.so

# here's the fallback if no module succeeds
auth    requisite                       pam_deny.so
# prime the stack with a positive return value if there isn't one already;
# this avoids us returning an error just because nothing sets a success code
# since the modules above will each just jump around
auth    required                        pam_permit.so
# and here are more per-package modules (the "Additional" block)
auth    optional                        pam_cap.so
# end of pam-auth-update config
```

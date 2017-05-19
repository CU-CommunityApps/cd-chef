# Override values from remote_syslog2-cookbook
# Use v0.19, instead of v0.17
default['remote_syslog2']['install']['download_file'] = 'https://github.com/papertrail/remote_syslog2/releases/download/v0.19/remote_syslog_linux_i386.tar.gz'
default['remote_syslog2']['install']['bin'] = 'remote_syslog2_0.19'
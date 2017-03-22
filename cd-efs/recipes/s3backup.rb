
package 's3cmd'

template '/root/efs-backup.sh' do
  source 's3backup/efs-backup.sh.erb'
  owner 'root'
  group 'root'
  mode '0744'
  variables({
    :filesystems => node['filesystems']
  })
  action :create
end

#See existing jobs: cat /var/spool/cron/crontabs/root
cron "backup-efs" do
  minute '0'
  hour '4'
  day '*'
  home '/root'
  command "/root/efs-backup.sh"
end


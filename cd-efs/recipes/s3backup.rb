
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

node['filesystems'].each do |group|

  group['mounts'].each do |efs|

    cron "backup-#{efs['efs_id']}" do
      minute '*/5'
      home '/'
      command %W{
        ls -al /mnt/#{group['ad_group_dir_name']}/#{efs['mount_dir_name']} >> /var/log/efs-backup.log &&
        date >> /var/log/efs-backup.log
      }.join(' ')
    end
    # "/mnt/#{group['ad_group_dir_name']}/#{efs['mount_dir_name']}"

  end

end


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

cron "backup-efs" do
  minute '*/5'
  home '/root'
  command "/root/efs-backup.sh"
end

node['filesystems'].each do |group|

  group['mounts'].each do |efs|

    cron "backup-#{efs['efs_id']}" do
      action 'delete'
      minute '*/5'
      home '/'
      command "/root/efs-backup.sh"
    end
    # "/mnt/#{group['ad_group_dir_name']}/#{efs['mount_dir_name']}"

  end

end

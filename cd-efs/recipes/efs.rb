package 'nfs-common'

directory '/mnt' do
  owner 'root'
  group 'root'
  mode '0755'
end

instance = search('aws_opsworks_instance', 'self:true').first
zone = instance['availability_zone']
stack = search('aws_opsworks_stack').first
region = stack['region']

node['filesystems'].each do |group|

  # Make group dir
  directory "/mnt/#{group['ad_group_dir_name']}" do
    owner 'root'
    group group['ad_group']
    mode '0750'
    retries 5
    retry_delay 30
  end

  group['mounts'].each do |efs|

    # Make mount dir
    mount_target = "/mnt/#{group['ad_group_dir_name']}/#{efs['mount_dir_name']}"
    file_target = "#{mount_target}/this-is-#{efs['efs_id']}.txt"
    directory mount_target do
      owner 'root'
      group node['sssd_config']['override_gid'].to_i
      mode '0770'
      not_if { ::File.exist?(file_target) }
    end

    mount mount_target do
      device  "#{zone}.#{efs['efs_id']}.efs.#{region}.amazonaws.com:/"
      fstype  'nfs4'
      options 'nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,bg'
      dump    0
      pass    0
      action  [:mount, :enable]
    end

    file file_target do
      content ""
      owner 'root'
      group 'root'
      mode '0644'
    end

  end

end

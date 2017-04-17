#
# Cookbook Name:: cd-jenkins
# Recipe:: default
#
# Copyright 2016, Cornell University
#
# All rights reserved - Do Not Redistribute
#
# 2017-04-06 : nl85 - adding attribute for EFS mount
#

yum_package 'nfs-utils'

user 'jenkins' do
  uid '1000'
end

group 'docker' do
  action :modify
  members 'jenkins'
  append true
end

directory '/var/jenkins_home' do
  owner 'jenkins'
  group 'jenkins'
  mode '0755'
  action :create
end

# used by cs-jenkins
#command "mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).fs-137fb25a.efs.us-east-1.amazonaws.com:/ /var/jenkins_home"

execute "mount efs directory" do
  command "mount -t nfs4 -o nfsvers=4.1 #{node['efs_dns']}:/ /var/jenkins_home"
  retries 1
  retry_delay 5
  not_if "grep -qs '/var/jenkins_home' /proc/mounts"
end

service 'docker' do
  action :restart
end

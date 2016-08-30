#
# Cookbook Name:: cd-jenkins
# Recipe:: default
#
# Copyright 2016, Cornell University
#
# All rights reserved - Do Not Redistribute
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

execute "mount efs directory" do
  command "mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).fs-137fb25a.efs.us-east-1.amazonaws.com:/ /var/jenkins_home"
  retries 1
  retry_delay 5
end

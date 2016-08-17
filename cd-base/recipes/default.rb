#
# Cookbook Name:: cs-base
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

if node[:platform_family].include?("debian")

  execute 'update_apt_keys' do
    command "curl -s 'https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e' | sudo apt-key add --import"
  end

  package 'linux-image-extra-virtual' do
    action :install
  end

  file '/etc/apt/sources.list.d/docker.list' do
    content 'deb https://packages.docker.com/1.11/apt/repo ubuntu-trusty main'
    mode '0644'
    owner 'root'
    group 'root'
  end

  apt_update 'name' do
    action :update
  end
  remote_file '/tmp/amazon-ssm-agent.deb' do
    source 'https://amazon-ssm-us-east-1.s3.amazonaws.com/latest/debian_amd64/amazon-ssm-agent.deb'
    action :create
  end

  dpkg_package 'ssm-agent' do
    source '/tmp/amazon-ssm-agent.deb'
  end

  file '/tmp/amazon-ssm-agent.deb' do
    action :delete
  end
else
  remote_file '/tmp/amazon-ssm-agent.rpm' do
    source 'https://amazon-ssm-us-east-1.s3.amazonaws.com/latest/linux_amd64/amazon-ssm-agent.rpm'
    action :create
  end

  rpm_package 'ssm-agent' do
    source '/tmp/amazon-ssm-agent.rpm'
  end

  file '/tmp/amazon-ssm-agent.rpm' do
    action :delete
  end
end

#
# Cookbook Name:: cd-tags
# Recipe:: default
#
# Copyright (c) 2016 Cornell University, All Rights Reserved.

include_recipe 'aws'

aws_resource_tag node['ec2']['instance_id'] do
  tags('os' => node['platform'])
  action :update
end

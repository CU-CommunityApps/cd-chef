#
# Cookbook Name:: cd-tags
# Recipe:: instance-tags
#
# Copyright (c) 2016 Cornell University, All Rights Reserved.

include_recipe 'aws'

node['instance-tags'].each do |tag|
  aws_resource_tag node['ec2']['instance_id'] do
    tags(tag['key'] => tag['value'])
    action :update
  end
end
#
# Cookbook Name:: cd-tags
# Recipe:: instance-tags
#
# Copyright (c) 2016 Cornell University, All Rights Reserved.

include_recipe 'aws'

# Rquires IAM policy something like this:

# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "Stmt1464916254000",
#             "Effect": "Allow",
#             "Action": [
#                 "ec2:CreateTags",
#                 "ec2:DeleteTags",
#                 "ec2:DescribeTags"
#             ],
#             "Resource": [
#                 "*"
#             ]
#         }
#     ]
# }

node['instance-tags'].each do |tag|
  aws_resource_tag node['ec2']['instance_id'] do
    tags(tag['key'] => tag['value'])
    action :update
  end
end
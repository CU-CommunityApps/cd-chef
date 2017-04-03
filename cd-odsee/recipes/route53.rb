instance = search("aws_opsworks_instance", "self:true").first
server_name = 'aws'+node['odsee']['environment']+'ds'+instance['hostname']
##################################################################
# Setup DNS
##################################################################
route53_record "route53-config" do
  name  server_name+'.cs.cucloud.net'
  value instance['public_ip']
  type  "A"

  zone_id node[:route53][:zone_id]
  overwrite true
  fail_on_error true
  action :create
end
#group 'docker' do
#    action :modify
#    members 'srb55'
#    append true
#end

template 'ecs.config' do
    path '/etc/ecs/ecs.config'
    source 'ecs.config.erb'
    owner 'root'
    group 'root'
    mode 0644
end

#docker_container 'ecs-agent' do
#    remove_volumes true
#    action :delete
#end

docker_image 'amazon/amazon-ecs-agent' do
#  tag 'latest'
  action :pull
end
#  notifies :redeploy, 'docker_container[ecs-agent]'
#end

#docker_container 'ecs-agent' do
#  image 'amazon/amazon-ecs-agent'
#  tag 'latest'
#  action :run_if_missing
#  detach true
#  port '127.0.0.1:51678:51678'
#  port '127.0.0.1:51678:51679'
#  restart_policy 'on-failure'
#  restart_maximum_retry_count 10
#  env lazy {
#    ::File.open('/etc/ecs/ecs.config').read.split("\n")
#  }
#  binds %w{
#    /var/run/docker.sock:/var/run/docker.sock
#    /var/log/ecs/:/log
#    /var/lib/ecs/data:/data
#    /sys/fs/cgroup:/sys/fs/cgroup:ro
#    /var/run/docker/execdriver/native:/var/lib/docker/execdriver/native:ro
#  }
#end

execute "Install the Amazon ECS agent" do
  command ["/usr/bin/docker",
           "run",
           "--name ecs-agent",
           "-d",
           "-v /var/log/ecs:/log",
           "-v /var/lib/ecs/data:/data",
           "-p 127.0.0.1:51678:51678",
           "-p 127.0.0.1:51679:51679",
           "--env-file /etc/ecs/ecs.config",
           "amazon/amazon-ecs-agent"].join(" ")
#           "amazon/amazon-ecs-agent:latest"].join(" ")
  retries 1
  retry_delay 5
  end

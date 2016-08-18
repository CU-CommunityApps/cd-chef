group 'docker' do
    action :modify
    members 'srb55'
    append true
end

template 'ecs.config' do
    path '/etc/ecs/ecs.config'
    source 'ecs.config.erb'
    owner 'root'
    group 'root'
    mode 0644
end

docker_container 'ecs-agent' do
    remove_volumes true
    action :delete
end

execute "Install the Amazon ECS agent" do
  command ["/usr/bin/docker",
           "run",
           "--name ecs-agent",
           "-d",
           "-v /var/run/docker.sock:/var/run/docker.sock",
           "-v /var/log/ecs:/log",
           "-v /var/lib/ecs/data:/data",
           "-p 127.0.0.1:51678:51678",
           "--env-file /etc/ecs/ecs.config",
           "amazon/amazon-ecs-agent:latest"].join(" ")
           
  retries 1
  retry_delay 5
end

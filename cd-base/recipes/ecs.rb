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

docker_container 'ecs-agent' do
    repo 'amazon/amazon-ecs-agent'
    tag 'latest'
    port '127.0.0.1:51678:51678'
    env-file '/etc/ecs/ecs.config'
    volumes ['/var/run/docker.sock:/var/run/docker.sock',
             '/var/log/ecs:/log',
             '/var/lib/ecs/data:/data']
end

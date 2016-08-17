group 'docker' do
  action :modify
  members 'srb55'
  append true
end

template "ecs.config" do
  path "/etc/ecs/ecs.config"
  source "ecs.config.erb"
  owner "root"
  group "root"
  mode 0644
end

docker_container 'ecs-agent' do
  action :restart
end

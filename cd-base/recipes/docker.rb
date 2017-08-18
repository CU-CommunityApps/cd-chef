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

else
  # add red hat instructions
end

package 'docker-engine' do
  action :install
end

#group 'docker' do
#  action :modify
#  members 'srb55'
#  append true
#end

service 'docker' do
  action :start
end

docker_registry 'https://dtr.cucloud.net/' do
  username node['dtr']['user']
  password node['dtr']['password']
  email ''
end

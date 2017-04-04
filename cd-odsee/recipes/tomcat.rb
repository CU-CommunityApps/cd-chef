# create user, group, assign permissions

group 'tomcat'

user 'tomcat' do
  group 'tomcat'
  home '/app/ldap/ds-7/apache-tomcat-7.0/'
  shell '/bin/nologin'
end

directory '/app/ldap/ds-7/apache-tomcat-7.0/' do
  owner 'root'
  group 'root'
  mode '0755'
end

# version: The version to install. Default: 8.0.36
# install_path: Full path to the install directory. Default: /opt/tomcat_INSTANCENAME_VERSION
# tarball_base_path: The base path to the apache mirror containing the tarballs. Default: 'http://archive.apache.org/dist/tomcat/'
# checksum_base_path: The base path to the apache mirror containing the md5 file. Default: 'http://archive.apache.org/dist/tomcat/'
# tarball_uri: The complete path to the tarball. If specified would override (tarball_base_path and checksum_base_path). checksum will be loaded from "#{tarball_uri}.md5". This attribute is useful, if you are hosting tomcat tarballs from artifact repositories such as nexus.
# exclude_docs: Exclude ./webapps/docs from installation. Default true.
# exclude_examples: Exclude ./webapps/examples from installation. Default true.
# exclude_manager: Exclude ./webapps/manager from installation. Default: false.
# exclude_hostmanager: Exclude ./webapps/host-manager from installation. Default: false.


tomcat_install 'odsee' do
  version '7.0.76'
  install_path node['odsee']['install']['install_path2']+'/apache-tomcat-7.0'
  exclude_docs true
  exclude_examples true
  exclude_manager false
  exclude_hostmanager false
end

# The war created by odsee is in /app/ldap/ds-7/dsee7/lib/web/dscc7_tmpl.war

# chmod, chgrp, chown stuff

execute 'change_permissions' do
  command 'chgrp -R tomcat conf'
  cwd '/opt/tomcat'
end

execute 'change_permissions2' do
  command 'chmod g+rwx conf'
  cwd '/opt/tomcat'
end

execute 'change_permissions3' do
  command 'chmod g+r conf/*'
  cwd '/opt/tomcat'
end

execute 'change_permissions4' do
  command 'chown -R tomcat logs/ temp/ webapps/ work/'
  cwd '/opt/tomcat'
end

# file edit
# sudo nano /app/ldap/ds-7/apache-tomcat-7.0/conf/web.xml
# in the same servlet as <servlet-name>jsp</servlet-name>
# add:
#                 <init-param>
#             <param-name>enablePooling</param-name>
#                     <param-value>false</param-value>
#                 </init-param>

# copy the war file
execute 'copy_war_file' do
  command "cp #{node['odsee']['install']['install_path']}/var/dscc7.war #{node['odsee']['install']['install_path2']}/apache-tomcat-7.0/webapps"
end

# make symlink
# i may have the from/to backwards
# i get ln wrong all the time
link '/app/ldap/ds-7/apache-tomcat'  do
  to '/app/ldap/ds-7/apache-tomcat-7.0/'
end

# start tomcat
execute 'start_tomcat' do
  command "#{node['odsee']['install']['install_path2']}/apache-tomcat-7.0/bin/startup.sh"
end

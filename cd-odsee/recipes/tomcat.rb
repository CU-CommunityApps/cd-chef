# version: The version to install. Default: 8.0.36
# install_path: Full path to the install directory. Default: /opt/tomcat_INSTANCENAME_VERSION
# tarball_base_path: The base path to the apache mirror containing the tarballs. Default: 'http://archive.apache.org/dist/tomcat/'
# checksum_base_path: The base path to the apache mirror containing the md5 file. Default: 'http://archive.apache.org/dist/tomcat/'
# tarball_uri: The complete path to the tarball. If specified would override (tarball_base_path and checksum_base_path). checksum will be loaded from "#{tarball_uri}.md5". This attribute is useful, if you are hosting tomcat tarballs from artifact repositories such as nexus.
# exclude_docs: Exclude ./webapps/docs from installation. Default true.
# exclude_examples: Exclude ./webapps/examples from installation. Default true.
# exclude_manager: Exclude ./webapps/manager from installation. Default: false.
# exclude_hostmanager: Exclude ./webapps/host-manager from installation. Default: false.


tomcat_install 'test' do
  version '7.0.76'
  install_path ndoe['odsee']['install']['install_path2']+'/apache-tomcat-7.0'
  exclude_docs true
  exclude_examples true
  exclude_manager true
  exclude_hostmanager true
end
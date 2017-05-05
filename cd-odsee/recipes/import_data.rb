##################################################################
# Import data
##################################################################

#
#
# work with Chris to export daily on-prem ldif from cork to aws S3 bucket
#
#

data_file = node['odsee']['import']['data_file']
data_file_target = "#{node['odsee']['install']['install_path']}/resources/#{data_file}"

if !data_file.nil? && !data_file.empty? then

  stack = search('aws_opsworks_stack').first
  aws_region = stack['region']

  aws_s3_file "#{data_file_target}.gz"  do
    bucket node['odsee']['import']['s3bucket']
    region aws_region
    remote_path "#{node['odsee']['import']['s3_key_prefix']}#{data_file}.gz"
    use_etag  true
    action :create
    owner 'ldap'
    group 'ldap'
    not_if { ::File.exist?(data_file_target) }
  end

  execute 'unzip-data' do
    command "gunzip -f #{data_file}.gz"
    creates data_file_target
    cwd "#{node['odsee']['install']['install_path']}/resources"
  end

# Some options for checking what records are imported already

# $ /app/ldap/ds-7/dsee7/bin/dsconf list-suffixes -c -w /tmp/admin_password.txt -v
# SUFFIX_DN                    entry-count  repl-role       repl-agmts  repl-priorities  indexes  encr-attrs
# ---------------------------  -----------  --------------  ----------  ---------------  -------  ----------
# dc=authz,dc=cornell,dc=edu             1  not-replicated         N/A              N/A       29           0
# dc=guests,dc=cornell,dc=edu            1  not-replicated         N/A              N/A       29           0
# o=cornell university,c=us              1  not-replicated         N/A              N/A       29           0
# o=“cornell                             1  not-replicated         N/A              N/A       29           0

# $ /app/ldap/ds-7/dsee7/bin/dsconf list-suffixes -c -w /tmp/admin_password.txt -v -E
# SUFFIX_DN                    PROP             VAL
# ---------------------------  ---------------  --------------
# dc=authz,dc=cornell,dc=edu   entry-count      1
# dc=authz,dc=cornell,dc=edu   repl-role        not-replicated
# dc=authz,dc=cornell,dc=edu   repl-agmts       N/A
# dc=authz,dc=cornell,dc=edu   repl-priorities  N/A
# dc=authz,dc=cornell,dc=edu   indexes          29
# dc=authz,dc=cornell,dc=edu   encr-attrs       0
# dc=guests,dc=cornell,dc=edu  entry-count      1
# dc=guests,dc=cornell,dc=edu  repl-role        not-replicated
# dc=guests,dc=cornell,dc=edu  repl-agmts       N/A
# dc=guests,dc=cornell,dc=edu  repl-priorities  N/A
# dc=guests,dc=cornell,dc=edu  indexes          29
# dc=guests,dc=cornell,dc=edu  encr-attrs       0
# o=cornell university,c=us    entry-count      1
# o=cornell university,c=us    repl-role        not-replicated
# o=cornell university,c=us    repl-agmts       N/A
# o=cornell university,c=us    repl-priorities  N/A
# o=cornell university,c=us    indexes          29
# o=cornell university,c=us    encr-attrs       0
# o=“cornell                   entry-count      1
# o=“cornell                   repl-role        not-replicated
# o=“cornell                   repl-agmts       N/A
# o=“cornell                  repl-priorities  N/A
# o=“cornell                   indexes          29
# o=“cornell                   encr-attrs       0


  admin_password_file = node['odsee']['credentials']['admin_password_file_name']

  execute "data-import" do
    command "bin/dsconf import --no-inter -p 389 -w #{admin_password_file} -e #{data_file_target} \"o=cornell university,c=us\""
    cwd node['odsee']['install']['install_path']
  end

end

# I also wanted to pass along information about initializing a schema.  One way to do this is to set up a replication agreement with an existing Directory Server instance.  We can do this with the following:
#
# sudo /app/ldap/ds-7/dsee7/bin/dsconf create-repl-agmt -h /app/ldap/ds-7/dsee7/slapd-awsdevds1 -p 389 o=“cornell university,c=us” devds1.drectory.cornell.edu:389
# sudo /app/ldap/ds-7/dsee7/bin/dsconf create-repl-agmt -h /app/ldap/ds-7/dsee7/slapd-awsdevds1 -p 389 dc=guests,dc=cornell,dc=edu devds1.drectory.cornell.edu:389
# sudo /app/ldap/ds-7/dsee7/bin/dsconf create-repl-agmt -h /app/ldap/ds-7/dsee7/slapd-awsdevds1 -p 389 dc=authz,dc=cornell,dc=edu devds1.drectory.cornell.edu:389
#
# The slapd-awsdevds1 and devds1.directory.cornell.edu parts will vary based on the server.
#
# We can also do this fairly simply through the UI, if you think this is a better alternative.  When we set up replication, we can skip the ldif import since the replication will happen automatically.  (However, we may want to do it depending on how long it takes for the replication to take place.)

%w[ o="cornell\ university,c=us" dc=guests,dc=cornell,dc=edu dc=authz,dc=cornell,dc=edu ].each do |suffix|
 execute suffix do
   command "#{node['odsee']['install']['install_path']}/bin/dsconf create-repl-agmt -h #{node['odsee']['install']['install_path']}/slapd-awsdevds1 -p 389 #{suffix} devds1.directory.cornell.edu:389"
 end
end

#
#
# parameterize direcory name and slapd-awsdevds1 names
# combine with import_data, pass in via json import vs replicate
#
#

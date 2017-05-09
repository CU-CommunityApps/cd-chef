###################
# decrypt passwords
###################
include_recipe "cd-odsee::secrets"

####################################################
# setup credentials, either with test or real values
####################################################
include_recipe "cd-odsee::setup_credentials"

########################
# build the odsee server
########################
include_recipe "cd-odsee::odsee_server"

#########################################
# determine where the data will come from
#########################################
read for data source from custom json
add_data_from_source = node['data']['source']

if add_data_from_source = "import"
  include_recipe "cd-odsee::import_data.rb"
end

if add_data_from_source = "replicate"
 include_recipe = "cd-odsee::replicate_data.rb"
end

# for now default to importing the data from file
# include_recipe "cd-odsee::import_data"

############################
# initialize tomcat instance
############################
# possibly to be removed when EB tomcat in place
include_recipe "cd-odsee::tomcat"

###########################
# clean up credential files
###########################
# Leave credentials in place during development
# include_recipe "cd-odsee::cleanup"

##################
# start the server
##################
# include_recipe "cd-odsee::start_server.rb"

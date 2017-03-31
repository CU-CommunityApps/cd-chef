include_recipe "cd-odsee::setup_credentials"
include_recipe "cd-odsee::odsee_server"
include_recipe "cd-odsee::import_data"

# Leave credentials in place during development
# include_recipe "cd-odsee::cleanup"

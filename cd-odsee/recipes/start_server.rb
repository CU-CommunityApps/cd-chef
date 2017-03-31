# This is the Makefile in scripts/ dir.
# I suspect we should use the commands directly instead of use the "make start" approach.

# $ cat Makefile
# all:
# 	-echo Valid targets are install, start and stop
#
#
# install:
# 	cp /app/ldap/ds-7/dsee7/slash/etc/cron.d/LDAP /etc/cron.d
# 	/app/ldap/ds-7/dsee7/scripts/installSource
#
# start:
# 	/app/ldap/ds-7/dsee7/scripts/startServices
#
# stop:
# 	/app/ldap/ds-7/dsee7/scripts/stopServices
#
# start-slapd:
# 	/app/ldap/ds-7/dsee7/scripts/startSlapd
#
# stop-slapd:
# 	/app/ldap/ds-7/dsee7/scripts/stopSlapd
#
# clean:
# 	/app/ldap/ds-7/dsee7/scripts/clean



install_path = node['odsee']['install']['install_path']

execute 'start-odsee' do
  command 'make start'
  cwd install_path+'scripts'
end

chef_gem 'i18n' do
  compile_time false
end

gem_package 'i18n'

require 'i18n'

include_recipe "odsee::install"
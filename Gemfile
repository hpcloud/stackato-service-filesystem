source (ENV['RUBYGEMS_MIRROR'] or :rubygems)

gem 'eventmachine'
gem "em-http-request"
gem "ruby-hmac"
gem "uuidtools"
gem "datamapper", ">= 0.10.2"
gem "dm-sqlite-adapter"
gem "do_sqlite3"
gem "sinatra"
gem "thin"

gem "net-ssh"

gem 'vcap_common', :require => ['vcap/common', 'vcap/component', 'vcap/util'], :path => '../../common'
gem 'vcap_logging', '>=0.1.3', :require => ['vcap/logging']
gem "vcap_services_base", :path => "../base"

group :test do
  gem "rake"
  gem "rspec"
  gem "simplecov"
  gem "simplecov-rcov"
  gem "ci_reporter"
end

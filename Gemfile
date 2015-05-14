source (ENV['RUBYGEMS_MIRROR'] or 'https://rubygems.org')

ruby '2.1.5' # prevents hard-to-diagnose errors with bundle install

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
gem "vcap_services_base", :path => "gems/base"

group :test do
  gem "rake"
  gem "rspec", "2.14.1"
  gem "simplecov"
  gem "simplecov-rcov"
  gem "ci_reporter"
end

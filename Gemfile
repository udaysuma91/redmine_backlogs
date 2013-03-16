source 'https://rubygems.org'

chiliproject_file = File.dirname(__FILE__) + "/lib/chili_project.rb"
chiliproject = File.file?(chiliproject_file)

gem "holidays", "~>1.0.3"
gem "icalendar"
gem "nokogiri"
gem "open-uri-cached"
gem "prawn"
gem 'json'
gem "system_timer" if RUBY_VERSION =~ /^1\.8\./ && RUBY_PLATFORM =~ /darwin|linux/

group :development do
  gem "inifile"
end

group :test do
  gem 'chronic'
  gem 'ZenTest', "=4.5.0" # 4.6.0 has a nasty bug that breaks autotest
  gem 'autotest-rails'
  gem 'capybara', "~> 1.1" if ENV['IN_RBL_TESTENV'] == 'true' # redmine 2.3 conflicts
  gem "poltergeist", "~>1.0"
  gem 'cucumber-rails'
  gem "culerity"
  gem "database_cleaner"
  gem "gherkin", "~> 2.6"
  gem "redgreen" if RUBY_VERSION < "1.9"
  gem "rspec", '~>2.11.0'
  gem "rspec-rails", '~> 2.11.0'
  if RUBY_VERSION >= "1.9"
    gem "simplecov", "~>0.6"
  else
    gem "rcov",  "=0.9.11"
  end
  gem "ruby-prof", :platforms => [:ruby]
  gem "spork"
  gem "test-unit", "=1.2.3" if RUBY_VERSION >= "1.9" and ENV['IN_RBL_TESTENV'] == 'true'
  gem "timecop", '~> 0.3.5'
end

# moved out of the dev group so backlogs can be tested by the user after install. Too many issues of weird setups with apache, nginx, etc.
# thin doesn't work for jruby
gem "thin", :platforms => [:ruby]

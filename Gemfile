source 'https://rubygems.org'
source 'https://gems.github.com'


# The gems that we use to test our stuff
def testing_gems
  gem 'rake'
  gem 'rspec', '~> 3.0.0'
  gem 'rspec-wait'
  gem 'cucumber'
  gem 'simplecov'
  gem 'bundler', '~> 1.6'
  gem 'bunny', '~> 1.4'
  gem 'sys-proctable'
  gem 'database_cleaner'
end

# The development (i.e. source code) versions of gems that are (or are needed by) our stuff
def dev_gems

  # Dev mode has to explicitly include every needed gem dependency in the project in order to
  # be properly (i.e. recursively) loaded from source by Bundler
  gem 'task_runner', :path => 'gems/task_runner'
  gem 'tef-worker', :path => 'gems/tef-worker'
  gem 'cuke_runner', :path => 'gems/cuke_runner'
  gem 'tef-worker-cuke_worker', :path => 'gems/tef-worker-cuke_worker'
  gem 'tef-queuebert', :path => 'gems/tef-queuebert'
  gem 'tef-core', :path => 'gems/tef-core'
  gem 'res_man', git: 'https://github.com/grange-insurance/res_man.git', branch: 'master'
  gem 'tef-manager', :path => 'gems/tef-manager'
  gem 'tef-keeper', :path => 'gems/tef-keeper'
  gem 'tef-cuke_keeper', :path => 'gems/tef-cuke_keeper'
  gem 'mdf', :path => 'gems/mdf'
  gem 'tef', :path => '.'
end

# The real (i.e. installed on the machine) versions gems that are (or are needed by) our stuff
def test_gems
  gem 'tef-worker'
  gem 'tef-worker-cuke_worker'
  gem 'tef-queuebert'
  gem 'tef-manager'
  gem 'tef-keeper'
  gem 'tef-cuke_keeper'
  gem 'mdf'
  gem 'tef'
end

# Nothing new to see here.
def prod_gems
  test_gems
end

puts "Bundler mode: #{ENV['BUNDLE_MODE']}"
mode = ENV['BUNDLE_MODE']

case mode
  when 'dev'
    testing_gems
    dev_gems
  when 'test', 'prod'
    testing_gems
    test_gems
  when 'prod'
    prod_gems
  else
    raise(ArgumentError, "Unknown bundle mode: #{mode}. Must be one of dev/test/prod.")
end
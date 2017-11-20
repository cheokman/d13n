require 'simplecov'
SimpleCov.start
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/"
  coverage_dir "#{File.dirname(__FILE__)}/../reports/coverage/"
end

require 'faker'
require 'factory_bot'
require 'as-duration'
require 'd13n'

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  #config.treat_symbols_as_metadata_keys_with_true_values = true
  # config.run_all_when_everything_filtered = true
  # config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # config.before(:suite) do

  # end

  # config.before(:each) do
  #   DatabaseCleaner.strategy = :transaction
  # end
  config.before(:each) do
    D13n.logger = D13n::Logger::SilenceLogger.new
  end

  # config.before(:each) do
  #   # open transaction
  #   DatabaseCleaner.clean_with :deletion
  #   DatabaseCleaner.start
  # end

  # config.after(:each) do
  #   DatabaseCleaner.clean
  # end

  FactoryBot.find_definitions
  config.profile_examples = 3

  config.include FactoryBot::Syntax::Methods
end


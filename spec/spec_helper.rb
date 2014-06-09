require 'simplecov'
require 'simplecov-rcov'
class SimpleCov::Formatter::MergedFormatter
  def format(result)
     SimpleCov::Formatter::HTMLFormatter.new.format(result)
     SimpleCov::Formatter::RcovFormatter.new.format(result)
  end
end
SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/.bundle/"
  add_filter "/lib/treetop/command.rb"
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require File.expand_path("../../spec/blueprints", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rspec'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
Dir[Rails.root.join("spec/integration/spec/helpers/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  ###########
  #capybara
  config.include Warden::Test::Helpers
  config.include Capybara::DSL,           example_group: { file_path: config.escaped_path(%w[spec integration])}
  config.include Capybara::CustomFinders, example_group: { file_path: config.escaped_path(%w[spec integration])}
  config.include Capybara::AccountHelper, example_group: { file_path: config.escaped_path(%w[spec integration])}
  config.include Capybara::CollectionHelper, example_group: { file_path: config.escaped_path(%w[spec integration])}
  config.include Capybara::SettingsHelper, example_group: { file_path: config.escaped_path(%w[spec integration])}
  config.include Capybara::MailHelper, example_group: { file_path: config.escaped_path(%w[spec integration])}
  config.filter_run_excluding(js: true)   unless config.filter_manager.inclusions[:js]

  Warden.test_mode!

  Capybara.default_wait_time = 5
  Capybara.javascript_driver = :selenium
  Capybara.default_selector = :css

  config.before :each do
    DatabaseCleaner.strategy = if Capybara.current_driver == :rack_test
      :transaction
    else
      [:truncation]
    end
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
    Timecop.return
  end
  ##########

  # Uncomment to view full backtraces
  # config.backtrace_clean_patterns = []

  # Helper for ignoring blocks of tests
  def ignore(*args); end;

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  def stub_time(time)
    time = Time.parse time
    Time.stub(:now) { time }
  end

  def with_tmp_file(filename)
    file = "#{Dir.tmpdir}/#{filename}"
    yield file
    File.delete file
  end

  $test_count = 0

  # Delete all test indexes after every 10 tests
  config.after(:each) do
    Tire::Index.new("collection_test_*").delete if (($test_count += 1) % 10 == 0)
  end

# Mock nuntium access and gateways management
  config.before(:each) do
    @nuntium = double("nuntium")
    Nuntium.stub(:new_from_config).and_return(@nuntium)
    @nuntium.stub(:create_channel)
    @nuntium.stub(:update_channel)
    @nuntium.stub(:delete_channel)
    Channel.any_instance.stub(:gateway_url).and_return(true)
    Channel.any_instance.stub(:handle_nuntium_channel_response).and_return(true)
  end

  module ActionController::TestCase::Behavior
    alias resource_map_get get

    def get(action, parameters = nil, session = nil, flash = nil)
      parameters ? parameters : parameters = {}
      parameters[:locale] = :en
      resource_map_get(action, parameters, session, flash)
    end
  end

  # Turn on all plugins by default
  module Settings
    CONFIG_SETTINGS = YAML.load_file(File.expand_path('../../config/settings.yml', __FILE__))

    def is_on?(plugin)
      true
    end

    def selected_plugins
      [self]
    end

    def method_missing(method_name)
      if method_name.to_s =~ /(\w+)\?$/
        true
      else
        CONFIG_SETTINGS[method_name.to_s]
      end
    end
  end
end

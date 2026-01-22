# frozen_string_literal: true

require 'capybara/rspec'

# Configure Capybara to use Selenium with headless Chrome
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Set default driver
Capybara.javascript_driver = :selenium_chrome_headless

# Configure Capybara settings
Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.default_driver = :rack_test
  config.app_host = 'http://localhost:3000'
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
end

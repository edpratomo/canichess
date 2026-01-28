# frozen_string_literal: true

module SystemSpecHelpers
  # Sign in helper for system tests
  def sign_in(user)
    visit new_user_session_path
    fill_in 'user_username', with: user.username
    fill_in 'user_password', with: user.password
    click_button 'Sign in'
  end

  # Sign out helper
  def sign_out
    click_link 'Sign out'
  end

  # Wait for element to appear
  def wait_for_element(selector, timeout: 5)
    Timeout.timeout(timeout) do
      sleep(0.1) until page.has_css?(selector)
    end
  end

  # Wait for AJAX to complete
  def wait_for_ajax(timeout: 5)
    Timeout.timeout(timeout) do
      loop until page.evaluate_script('jQuery.active').zero?
    rescue StandardError
      break
    end
  end

  # Accept confirmation dialog
  def accept_confirm
    page.driver.browser.switch_to.alert.accept if Capybara.current_driver == :selenium_chrome_headless
    yield if block_given?
  end

  # Dismiss confirmation dialog
  def dismiss_confirm
    page.driver.browser.switch_to.alert.dismiss if Capybara.current_driver == :selenium_chrome_headless
    yield if block_given?
  end

  # Take screenshot for debugging
  def take_debug_screenshot(name = 'debug')
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    filename = "#{name}_#{timestamp}.png"
    save_screenshot(Rails.root.join('tmp', 'screenshots', filename))
  end

  # Fill in form with hash of attributes
  def fill_form(attributes)
    attributes.each do |field, value|
      case value
      when TrueClass
        check field
      when FalseClass
        uncheck field
      when Array
        value.each { |v| check v }
      else
        fill_in field, with: value
      end
    end
  end

  # Create and sign in as admin user
  def sign_in_as_admin
    admin = create(:user, username: 'admin', email: 'admin@test.com', password: 'password123')
    sign_in(admin)
    admin
  end

  # Navigate to admin dashboard
  def visit_admin_dashboard
    visit admin_path
  end

  # Check for flash messages
  def expect_flash_message(type, message)
    within('.flash') do
      expect(page).to have_content(message)
    end
  end

  # Retry action on stale element
  def retry_on_stale(retries: 3)
    attempts = 0
    begin
      yield
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      attempts += 1
      retry if attempts < retries
      raise
    end
  end
end

RSpec.configure do |config|
  config.include SystemSpecHelpers, type: :system
end

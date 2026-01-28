# System Specs for Canichess

This directory contains system-level integration tests (also known as feature specs) for the Canichess chess tournament management application.

## Overview

System specs test the application from the user's perspective, simulating real browser interactions using Capybara. They verify that different parts of the application work correctly together.

## Structure

```
spec/system/
├── admin/
│   ├── boards_spec.rb              # Admin board management tests
│   ├── tournaments_spec.rb         # Admin tournament CRUD tests
│   └── tournaments_players_spec.rb # Admin player management tests
├── home_spec.rb                    # Public home page tests
├── tournaments_spec.rb             # Public tournament viewing tests
└── user_authentication_spec.rb    # Authentication flow tests
```

## Running System Specs

**Prerequisites**: 
- NODE_OPTIONS is configured in `.env.test` for Webpacker compatibility
- Compile test assets if needed: `RAILS_ENV=test bundle exec rails webpacker:compile`

### Run all system specs
```bash
bundle exec rspec spec/system
```

### Run specific spec file
```bash
bundle exec rspec spec/system/user_authentication_spec.rb
```

### Run specific test
```bash
bundle exec rspec spec/system/user_authentication_spec.rb:10
```

### Run with specific driver (headless Chrome)
```bash
bundle exec rspec spec/system --tag js
```

## Configuration

### Drivers

The application uses two drivers:
- **rack_test**: Default driver for fast tests without JavaScript
- **selenium_chrome_headless**: For tests requiring JavaScript execution

Configuration is in `spec/support/capybara.rb`.

### Test Data

System specs use FactoryBot factories defined in `spec/factories.rb` to create test data.

## Coverage

### User Authentication (`user_authentication_spec.rb`)
- Sign in with valid/invalid credentials
- Sign out functionality
- Profile editing
- Protected page access

### Public Tournaments (`tournaments_spec.rb`)
- Viewing tournament lists
- Viewing tournament groups
- Viewing players
- Viewing pairings and standings
- Navigation between rounds

### Admin Tournaments (`admin/tournaments_spec.rb`)
- Creating tournaments
- Editing tournaments
- Deleting tournaments
- Managing groups
- Starting tournaments
- Managing sponsors and labels

### Admin Tournament Players (`admin/tournaments_players_spec.rb`)
- Adding single players
- Bulk uploading players from CSV
- Editing player details
- Removing players
- Managing player labels
- Moving players between groups

### Admin Boards (`admin/boards_spec.rb`)
- Viewing boards by round/group
- Editing board results
- Handling bye and walkover boards
- Deleting boards

### Home Page (`home_spec.rb`)
- Public homepage functionality
- Tournament listings
- Navigation
- Contact page

## Best Practices

### 1. Use Descriptive Contexts
```ruby
describe 'User Authentication' do
  context 'with valid credentials' do
    it 'allows sign in' do
      # test code
    end
  end
  
  context 'with invalid credentials' do
    it 'shows error message' do
      # test code
    end
  end
end
```

### 2. Use Helper Methods
```ruby
# Instead of repeating sign in code
sign_in user

# Instead of manual form filling
fill_form(name: 'Test', email: 'test@example.com')
```

### 3. Test User Flows
System specs should test complete user workflows, not individual methods:
```ruby
it 'creates a tournament with players' do
  visit new_admin_tournament_path
  fill_in 'Name', with: 'Test Tournament'
  click_button 'Create Tournament'
  click_link 'Add Players'
  # ... complete workflow
end
```

### 4. Use Database Cleaner
System specs use `use_transactional_fixtures = false` in `rails_helper.rb` to support JavaScript-enabled tests.

### 5. Debugging Failed Tests
```ruby
# Take a screenshot
take_debug_screenshot('failed_test')

# Print page HTML
puts page.html

# Check current path
puts current_path

# Save and open page
save_and_open_page
```

## Common Patterns

### Testing Forms
```ruby
it 'creates a resource' do
  visit new_resource_path
  
  fill_in 'Name', with: 'Test Name'
  select 'Option', from: 'Select Field'
  check 'Checkbox'
  
  click_button 'Create'
  
  expect(page).to have_content('successfully created')
end
```

### Testing Lists
```ruby
it 'displays all items' do
  items = create_list(:item, 3)
  
  visit items_path
  
  items.each do |item|
    expect(page).to have_content(item.name)
  end
end
```

### Testing Navigation
```ruby
it 'navigates through pages' do
  visit root_path
  click_link 'Tournaments'
  expect(page).to have_current_path(tournaments_path)
  
  click_link tournament.name
  expect(page).to have_current_path(tournament_path(tournament))
end
```

### Testing with JavaScript
```ruby
it 'handles AJAX requests', js: true do
  visit page_with_ajax_path
  
  click_button 'Load More'
  
  wait_for_ajax
  expect(page).to have_css('.item', count: 10)
end
```

## Adding New System Specs

1. Create a new file in `spec/system/` or `spec/system/admin/`
2. Follow the naming convention: `<feature>_spec.rb`
3. Include appropriate setup:
```ruby
require 'rails_helper'

RSpec.describe 'Feature Name', type: :system do
  before do
    driven_by(:rack_test)
  end
  
  # Your tests here
end
```

4. Add JavaScript driver when needed:
```ruby
before do
  driven_by(:selenium_chrome_headless)
end
```

## Continuous Integration

System specs are designed to run in CI environments. The headless Chrome driver is configured for CI compatibility.

## Troubleshooting

### Slow Tests
- Use `rack_test` driver when JavaScript is not needed
- Clean up test data properly
- Use `let!` sparingly, prefer `let` when possible

### Flaky Tests
- Add explicit waits: `expect(page).to have_content('text')`
- Use `wait_for_ajax` helper
- Increase `default_max_wait_time` in capybara config if needed

### Element Not Found
- Verify element exists: `puts page.html`
- Check for timing issues
- Ensure correct driver is used (rack_test vs selenium)

### Database Issues
- Ensure database cleaner is configured
- Check for transaction issues with JavaScript tests
- Verify test data is created in correct order

## Resources

- [RSpec Rails](https://github.com/rspec/rspec-rails)
- [Capybara Documentation](https://github.com/teamcapybara/capybara)
- [FactoryBot](https://github.com/thoughtbot/factory_bot)
- [Selenium WebDriver](https://www.selenium.dev/documentation/webdriver/)

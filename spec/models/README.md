# RSpec Model Tests

This directory contains comprehensive RSpec tests for all Rails models in the Canichess application.

## Overview

The test suite includes:

- **Factory definitions** (`factories.rb`) - FactoryBot factories for all models
- **Model specs** - Comprehensive tests for validations, associations, callbacks, and methods

## Models Covered

1. **Player** - User profiles, ratings, FIDE data, affiliation
2. **Tournament** - Tournament management, groups, player registration
3. **Group** - Abstract base class for tournament systems (STI)
4. **Swiss** - Swiss system implementation with pairing algorithms
5. **RoundRobin** - Round-robin tournament system
6. **Board** - Individual game boards with results
7. **Standing** - Round-by-round standings and tiebreaks
8. **TournamentsPlayer** - Join model for tournament participation
9. **Sponsor** - Event sponsors with logo attachments
10. **EventsSponsor** - Polymorphic join for sponsor associations
11. **User** - Devise authentication and Gravatar integration
12. **Simul** - Simultaneous exhibition events
13. **SimulsPlayer** - Simul participation records
14. **MergedStanding** - Combined standings across multiple tournaments
15. **MergedStandingsConfig** - Configuration for merged standings

## Running Tests

### Run all model specs:
```bash
bundle exec rspec spec/models
```

### Run a specific model spec:
```bash
bundle exec rspec spec/models/player_spec.rb
```

### Run with detailed output:
```bash
bundle exec rspec spec/models --format documentation
```

### Run with coverage:
```bash
COVERAGE=true bundle exec rspec spec/models
```

## Key Testing Patterns

### PostgreSQL Triggers
Note that this application uses PostgreSQL triggers for updating player points instead of ActiveRecord callbacks. Tests account for this by:
- Not expecting callbacks to update points automatically
- Testing the trigger behavior separately if needed
- Using factories to set up proper initial states

### Factories Usage
All tests use FactoryBot factories instead of fixtures for maximum flexibility:

```ruby
# Create a player
player = create(:player)

# Create with specific attributes
player = create(:player, :student, rating: 1800)

# Build without saving
player = build(:player)
```

### Testing Associations
```ruby
it { is_expected.to belong_to(:tournament) }
it { is_expected.to have_many(:players).through(:tournaments_players) }
```

### Testing Callbacks
```ruby
describe 'after_create' do
  it 'creates a default group' do
    tournament = create(:tournament)
    expect(tournament.groups.count).to eq(1)
  end
end
```

### Testing Methods
```ruby
describe '#canisian?' do
  it 'returns true for students' do
    player = create(:player, :student)
    expect(player.canisian?).to be true
  end
end
```

## Database Considerations

- Tests use PostgreSQL (not SQLite) to match production
- Transactional fixtures are enabled for test isolation
- Database cleaner may be needed for some integration tests
- PostgreSQL triggers are present and active during tests

## Troubleshooting

### Common Issues

1. **Factory validation errors**: Check that all required associations are properly created
2. **Callback not firing**: Remember some updates use PostgreSQL triggers, not AR callbacks
3. **Association not found**: Ensure proper test database setup with `rails db:test:prepare`

### Reset test database:
```bash
RAILS_ENV=test rails db:drop db:create db:migrate
```

### Check factory definitions:
```bash
bundle exec rails c test
FactoryBot.lint
```

## Test Coverage Areas

Each model spec typically covers:

1. **Associations** - `belongs_to`, `has_many`, `has_one`, `through`
2. **Validations** - Presence, uniqueness, numericality, custom validators
3. **Callbacks** - `before_*`, `after_*`, `around_*` hooks
4. **Scopes** - Named scopes and query methods
5. **Instance Methods** - Public methods and their edge cases
6. **Class Methods** - Static/class-level functionality
7. **Enums** - Enumerated types and state transitions
8. **STI** - Single Table Inheritance behavior (Group/Swiss/RoundRobin)
9. **Polymorphic Associations** - EventsSponsor polymorphism
10. **Complex Business Logic** - Tournament pairing, tiebreak calculations, rating updates

## Notes on PostgreSQL Triggers

The application uses PostgreSQL triggers for performance-critical operations:

- **Points calculation** - Player points are updated via triggers when board results change
- **Tiebreak calculations** - Some tiebreaks may use database-level computation

Tests handle this by:
- Reloading records after operations that trigger database updates
- Testing final state rather than intermediate callback behavior
- Using integration tests for full workflow verification

## Contributing

When adding new models or modifying existing ones:

1. Update the corresponding factory in `spec/factories.rb`
2. Add/update model specs following the existing patterns
3. Test all validations, associations, and public methods
4. Include edge cases and error conditions
5. Document any PostgreSQL trigger interactions
6. Run the full test suite to ensure no regressions

## Related Documentation

- [RSpec Rails Documentation](https://github.com/rspec/rspec-rails)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot)
- [Shoulda Matchers](https://github.com/thoughtbot/shoulda-matchers) - Used for association/validation tests

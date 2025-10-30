# RuboCop RSpec Guide

[![Gem Version](https://badge.fury.io/rb/rubocop-rspec-guide.svg)](https://badge.fury.io/rb/rubocop-rspec-guide)
[![Downloads](https://img.shields.io/gem/dt/rubocop-rspec-guide.svg)](https://rubygems.org/gems/rubocop-rspec-guide)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.0.0-blue.svg)](https://www.ruby-lang.org)

Custom RuboCop cops that enforce best practices from the [RSpec Style Guide](https://github.com/AlexeyMatskevich/rspec-guide).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rubocop-rspec-guide', require: false
```

Or install it yourself:

```bash
gem install rubocop-rspec-guide
```

## Usage

### Modern Approach (RuboCop 1.72+)

Add to your `.rubocop.yml`:

```yaml
# Modern plugin system (recommended for RuboCop 1.72+)
plugins:
  - rubocop-rspec-guide

# Optionally inherit the default config
inherit_gem:
  rubocop-rspec-guide: config/default.yml

# Recommended: Enable RSpec/LeadingSubject to ensure subject is at describe level
RSpec/LeadingSubject:
  Enabled: true
```

### Legacy Approach (RuboCop < 1.72)

For older versions of RuboCop, use `require:` instead:

```yaml
# Legacy require system (for RuboCop < 1.72)
require:
  - rubocop-rspec-guide

# Optionally inherit the default config
inherit_gem:
  rubocop-rspec-guide: config/default.yml

# Recommended: Enable RSpec/LeadingSubject to ensure subject is at describe level
RSpec/LeadingSubject:
  Enabled: true
```

### Individual Configuration

Configure cops individually with either approach:

```yaml
# Use 'plugins:' (RuboCop 1.72+) or 'require:' (older versions)
plugins:
  - rubocop-rspec-guide

RSpecGuide/MinimumBehavioralCoverage:
  Enabled: true

RSpecGuide/HappyPathFirst:
  Enabled: true

RSpecGuide/ContextSetup:
  Enabled: true

RSpecGuide/DuplicateLetValues:
  Enabled: true

RSpecGuide/DuplicateBeforeHooks:
  Enabled: true

RSpecGuide/InvariantExamples:
  Enabled: true
  MinLeafContexts: 3

FactoryBotGuide/DynamicAttributeEvaluation:
  Enabled: true
```

## Cops

### RSpecGuide/MinimumBehavioralCoverage

Requires at least 2 behavioral variations in a describe block: either 2+ sibling contexts OR it-blocks + context-blocks.

```ruby
# bad
describe '#calculate' do
  it 'works' { expect(result).to eq(100) }
end

# good - 2+ contexts
describe '#calculate' do
  context 'with valid data' do
    it { expect(result).to eq(100) }
  end

  context 'with invalid data' do
    it { expect(result).to be_error }
  end
end

# good - it-blocks + context-blocks
describe '#calculate' do
  it 'works with defaults' do
    expect(result).to eq(100)
  end

  context 'with invalid data' do
    it { expect(result).to be_error }
  end
end
```

**Note:** The old name `RSpecGuide/CharacteristicsAndContexts` is deprecated but still works as an alias.

### RSpecGuide/HappyPathFirst

Ensures corner cases are not placed before happy paths.

```ruby
# bad
describe '#process' do
  context 'but user is blocked' do
    # ...
  end
  context 'when user is valid' do
    # ...
  end
end

# good
describe '#process' do
  context 'when user is valid' do
    # ...
  end
  context 'but user is blocked' do
    # ...
  end
end
```

### RSpecGuide/ContextSetup

Requires contexts to have setup (let/let!/let_it_be/let_it_be!/before) to distinguish them from parent.

**Note:** `subject` should be defined at `describe` level, not in contexts, as it describes the object under test. Use `RSpec/LeadingSubject` cop to ensure subject is defined first.

```ruby
# bad - no setup
context 'when premium' do
  it { expect(user).to have_access }
end

# bad - subject in context (should be in describe)
context 'when premium' do
  subject { user }  # Wrong place!
  it { is_expected.to have_access }
end

# good - let defines context-specific state
context 'when premium' do
  let(:user) { create(:user, :premium) }
  it { expect(user).to have_access }
end

# good - let_it_be for performance (from test-prof/rspec-rails)
context 'when premium' do
  let_it_be(:user) { create(:user, :premium) }
  it { expect(user).to have_access }
end

# good - before sets up context
context 'when premium' do
  before { user.upgrade_to_premium! }
  it { expect(user).to have_access }
end
```

### RSpecGuide/DuplicateLetValues

Detects duplicate let declarations across sibling contexts with severity levels.

**Severity Levels:**
- **ERROR** - When let is duplicated in ALL sibling contexts → must extract to parent
- **WARNING** - When let is duplicated in 2+ contexts but not all → suggests bad test hierarchy

```ruby
# bad - ERROR (in ALL contexts)
context 'A' do
  let(:currency) { :usd }
end
context 'B' do
  let(:currency) { :usd }  # duplicate in all!
end

# bad - WARNING (partial duplicate, code smell)
context 'A' do
  let(:currency) { :usd }
end
context 'B' do
  let(:currency) { :usd }  # duplicated in 2/3 contexts
end
context 'C' do
  let(:currency) { :eur }  # different value
end

# good
let(:currency) { :usd }  # extract to parent
context 'A' do; end
context 'B' do; end
```

**Configuration:**
```yaml
RSpecGuide/DuplicateLetValues:
  WarnOnPartialDuplicates: true  # Show warnings for partial duplicates (default: true)
```

### RSpecGuide/DuplicateBeforeHooks

Detects duplicate before hooks across sibling contexts with severity levels.

**Severity Levels:**
- **ERROR** - When before hook is duplicated in ALL sibling contexts → must extract to parent
- **WARNING** - When before hook is duplicated in 2+ contexts but not all → suggests bad test hierarchy

```ruby
# bad - ERROR (in ALL contexts)
context 'A' do
  before { sign_in(user) }
end
context 'B' do
  before { sign_in(user) }  # duplicate in all!
end

# bad - WARNING (partial duplicate, code smell)
context 'A' do
  before { setup }
end
context 'B' do
  # no before
end
context 'C' do
  before { setup }  # duplicated in 2/3 contexts
end

# good
before { sign_in(user) }  # extract to parent
context 'A' do; end
context 'B' do; end
```

**Configuration:**
```yaml
RSpecGuide/DuplicateBeforeHooks:
  WarnOnPartialDuplicates: true  # Show warnings for partial duplicates (default: true)
```

### RSpecGuide/InvariantExamples

Detects examples repeated in all leaf contexts.

```ruby
# bad - same example in all 3 contexts
context 'A' do
  it 'responds to valid?' { }
end
context 'B' do
  it 'responds to valid?' { }
end
context 'C' do
  it 'responds to valid?' { }
end

# good - extract to shared_examples
shared_examples 'a validator' do
  it 'responds to valid?' { }
end

context 'A' do
  it_behaves_like 'a validator'
end
```

### FactoryBotGuide/DynamicAttributeEvaluation

Ensures method calls in factory attributes are wrapped in blocks for dynamic evaluation.

```ruby
# bad - method calls evaluated once at factory load time
factory :user do
  created_at Time.now       # same timestamp for all users!
  token SecureRandom.hex    # same token for all users!
  expires_at 1.day.from_now # same expiry for all users!
  tags Array.new            # same array instance shared!
end

# good - wrapped in blocks for dynamic evaluation
factory :user do
  created_at { Time.now }
  token { SecureRandom.hex }
  expires_at { 1.day.from_now }
  tags { Array.new }
  name "John"               # static values are OK
end
```

**Note:** The old name `FactoryBotGuide/DynamicAttributesForTimeAndRandom` is deprecated but still works as an alias.

## Development

After checking out the repo:

```bash
bundle install
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## References

- [RSpec Style Guide](https://github.com/AlexeyMatskevich/rspec-guide)
- [RuboCop RSpec](https://github.com/rubocop/rubocop-rspec)

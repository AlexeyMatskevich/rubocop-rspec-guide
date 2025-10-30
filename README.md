# RuboCop RSpec Guide

[![Gem Version](https://badge.fury.io/rb/rubocop-rspec-guide.svg)](https://badge.fury.io/rb/rubocop-rspec-guide)
[![CI](https://github.com/rspec-guide/rubocop-rspec-guide/workflows/CI/badge.svg)](https://github.com/rspec-guide/rubocop-rspec-guide/actions)
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

### Quick Start

1. **Add to Gemfile:**
   ```ruby
   group :development, :test do
     gem 'rubocop-rspec-guide', require: false
   end
   ```

2. **Install:**
   ```bash
   bundle install
   ```

3. **Configure `.rubocop.yml`:**
   
   **Minimal configuration (v0.4.0+):**
   ```yaml
   # RuboCop 1.72+
   plugins:
     - rubocop-rspec-guide
   
   # RuboCop < 1.72
   require:
     - rubocop-rspec-guide
   ```
   
   The gem automatically loads its default configuration, including RSpec Language settings.
   
   **Optional - explicit config inheritance:**
   
   If you want to explicitly inherit the config (not required):
   ```yaml
   plugins:
     - rubocop-rspec-guide
   
   inherit_gem:
     rubocop-rspec-guide: config/default.yml
   ```

4. **Run RuboCop:**
   ```bash
   bundle exec rubocop
   ```

5. **Fix offenses automatically (where possible):**
   ```bash
   bundle exec rubocop -a
   # or for safe autocorrection only:
   bundle exec rubocop -A
   ```

### Autocorrection Support

Some cops support **automatic correction** with `rubocop -a`:

| Cop | Autocorrect | Safety |
|-----|-------------|--------|
| `FactoryBotGuide/DynamicAttributeEvaluation` | ✅ Yes | Safe |
| `RSpecGuide/MinimumBehavioralCoverage` | ❌ No | - |
| `RSpecGuide/HappyPathFirst` | ❌ No | - |
| `RSpecGuide/ContextSetup` | ❌ No | - |
| `RSpecGuide/DuplicateLetValues` | ❌ No | - |
| `RSpecGuide/DuplicateBeforeHooks` | ❌ No | - |
| `RSpecGuide/InvariantExamples` | ❌ No | - |

**Example of autocorrection:**

```ruby
# Before: offense detected
factory :user do
  created_at Time.now
  token SecureRandom.hex
end

# After: rubocop -a
factory :user do
  created_at { Time.now }
  token { SecureRandom.hex }
end
```

### Common Patterns

#### Pattern 1: Testing Happy Path + Edge Cases

```ruby
# Before (offense)
describe '#calculate_discount' do
  it 'calculates discount' do
    expect(calculate_discount(100)).to eq(10)
  end
end

# After (fixed)
describe '#calculate_discount' do
  context 'with standard price' do
    it { expect(calculate_discount(100)).to eq(10) }
  end

  context 'with zero price' do
    it { expect(calculate_discount(0)).to eq(0) }
  end

  context 'with negative price' do
    it { expect { calculate_discount(-10) }.to raise_error(ArgumentError) }
  end
end
```

#### Pattern 2: It-blocks + Context-blocks

```ruby
# Good - default behavior + edge cases
describe '#process_payment' do
  it 'processes payment successfully' do
    expect(process_payment).to be_success
  end

  context 'when payment gateway is down' do
    before { stub_gateway_down }
    it { expect(process_payment).to be_failure }
  end

  context 'with insufficient funds' do
    let(:balance) { 0 }
    it { expect(process_payment).to be_declined }
  end
end
```

#### Pattern 3: Extracting Duplicate Setup

```ruby
# Before (offense - duplicate let in all contexts)
describe 'PaymentProcessor' do
  context 'with credit card' do
    let(:currency) { :usd }
    it { expect(process).to be_success }
  end

  context 'with paypal' do
    let(:currency) { :usd }  # Duplicate!
    it { expect(process).to be_success }
  end
end

# After (fixed - extracted to parent)
describe 'PaymentProcessor' do
  let(:currency) { :usd }  # Moved to parent

  context 'with credit card' do
    it { expect(process).to be_success }
  end

  context 'with paypal' do
    it { expect(process).to be_success }
  end
end
```

### Configuration Examples

#### Complete Setup (with rubocop-rspec and rubocop-factory_bot)

Most projects use `rubocop-rspec-guide` alongside `rubocop-rspec` and `rubocop-factory_bot`. Here's a complete configuration:

```yaml
# .rubocop.yml

# Load all RSpec-related extensions
require:
  - rubocop-rspec
  - rubocop-rspec_rails  # If using Rails
  - rubocop-factory_bot
  - rubocop-rspec-guide

# Or use plugins syntax (RuboCop 1.72+):
# plugins:
#   - rubocop-rspec
#   - rubocop-rspec_rails
#   - rubocop-factory_bot
#   - rubocop-rspec-guide

# RSpec cops (from rubocop-rspec)
RSpec/VerifiedDoubles:
  Enabled: true

RSpec/MessageSpies:
  Enabled: true
  EnforcedStyle: have_received

# FactoryBot cops (from rubocop-factory_bot)
FactoryBot/CreateList:
  Enabled: true

# RSpec Style Guide cops (from rubocop-rspec-guide)
RSpecGuide/MinimumBehavioralCoverage:
  Enabled: true

RSpecGuide/HappyPathFirst:
  Enabled: true

RSpecGuide/ContextSetup:
  Enabled: true

FactoryBotGuide/DynamicAttributeEvaluation:
  Enabled: true
```

**Note:** The gem automatically injects RSpec Language configuration (v0.4.0+), so no `inherit_gem` is needed.

#### Strict Mode (for new projects)

```yaml
require:
  - rubocop-rspec-guide

RSpecGuide/MinimumBehavioralCoverage:
  Enabled: true

RSpecGuide/HappyPathFirst:
  Enabled: true

RSpecGuide/ContextSetup:
  Enabled: true

RSpecGuide/DuplicateLetValues:
  Enabled: true
  WarnOnPartialDuplicates: true

RSpecGuide/DuplicateBeforeHooks:
  Enabled: true
  WarnOnPartialDuplicates: true

RSpecGuide/InvariantExamples:
  Enabled: true
  MinLeafContexts: 3

FactoryBotGuide/DynamicAttributeEvaluation:
  Enabled: true
```

#### Relaxed Mode (for legacy projects)

```yaml
require:
  - rubocop-rspec-guide

# Enable only critical cops
RSpecGuide/MinimumBehavioralCoverage:
  Enabled: true

RSpecGuide/ContextSetup:
  Enabled: true

# Disable warnings for partial duplicates
RSpecGuide/DuplicateLetValues:
  Enabled: true
  WarnOnPartialDuplicates: false

RSpecGuide/DuplicateBeforeHooks:
  Enabled: true
  WarnOnPartialDuplicates: false

# More lenient threshold for invariants
RSpecGuide/InvariantExamples:
  Enabled: true
  MinLeafContexts: 5  # Only report if in 5+ contexts

# Disable strict cops
RSpecGuide/HappyPathFirst:
  Enabled: false

FactoryBotGuide/DynamicAttributeEvaluation:
  Enabled: true
```

### Troubleshooting

#### Issue: Too many offenses in existing codebase

**Solution:** Enable cops gradually:

```yaml
# Start with most important cops
RSpecGuide/ContextSetup:
  Enabled: true

FactoryBotGuide/DynamicAttributeEvaluation:
  Enabled: true

# Disable others temporarily
RSpecGuide/MinimumBehavioralCoverage:
  Enabled: false

RSpecGuide/DuplicateLetValues:
  Enabled: false
```

Then enable one cop at a time, fix offenses, and move to the next.

#### Issue: False positives on simple getters

**Solution:** Disable cop for specific tests:

```ruby
describe '#name' do # rubocop:disable RSpecGuide/MinimumBehavioralCoverage
  it { expect(subject.name).to eq('test') }
end
```

#### Issue: "Duplicate let" warning but values are contextual

**Solution:** This usually indicates poor test hierarchy. Refactor:

```ruby
# Before - partial duplicates (2/3 contexts)
describe 'Converter' do
  context 'scenario A' do
    let(:format) { :json }
    # ...
  end
  context 'scenario B' do
    let(:format) { :json }  # Duplicate!
    # ...
  end
  context 'scenario C' do
    let(:format) { :xml }  # Different
    # ...
  end
end

# After - better hierarchy
describe 'Converter' do
  context 'with JSON format' do
    let(:format) { :json }
    
    context 'scenario A' do
      # ...
    end
    
    context 'scenario B' do
      # ...
    end
  end
  
  context 'with XML format' do
    let(:format) { :xml }
    
    context 'scenario C' do
      # ...
    end
  end
end
```

### Migration Guide

#### Upgrading to v0.4.0

**Configuration changes:**

Starting from v0.4.0, the gem automatically injects its default configuration, including RSpec Language settings. You can simplify your `.rubocop.yml`:

```yaml
# Before (v0.3.x) - explicit inheritance required
plugins:
  - rubocop-rspec-guide

inherit_gem:
  rubocop-rspec-guide: config/default.yml

# After (v0.4.0+) - automatic config injection
plugins:
  - rubocop-rspec-guide
```

**What changed:**
- ✅ `let_it_be` and `let_it_be!` are now automatically recognized (from `test-prof` / `rspec-rails`)
- ✅ All cops now use `RuboCop::Cop::RSpec::Base` for better RSpec DSL detection
- ✅ Significant performance improvement: `InvariantExamples` is 4.25x faster
- ✅ More accurate detection of RSpec constructs

**No code changes needed** - your existing RSpec tests will work as before, but with better analysis.

#### From CharacteristicsAndContexts to MinimumBehavioralCoverage

The old name still works as an alias, but you should update your config:

```yaml
# Old (deprecated)
RSpecGuide/CharacteristicsAndContexts:
  Enabled: true

# New (recommended)
RSpecGuide/MinimumBehavioralCoverage:
  Enabled: true
```

No code changes needed - the cop behavior is the same.

#### From DynamicAttributesForTimeAndRandom to DynamicAttributeEvaluation

The old name still works as an alias:

```yaml
# Old (deprecated)
FactoryBotGuide/DynamicAttributesForTimeAndRandom:
  Enabled: true

# New (recommended)
FactoryBotGuide/DynamicAttributeEvaluation:
  Enabled: true
```

The new cop checks ALL method calls, not just Time/Random, providing better coverage.

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

## Documentation

Full API documentation is available:

- **Generate locally**: `bundle exec rake doc`
- **View documentation**: Open `doc/index.html` in your browser
- **Quick open**: `bundle exec rake doc_open`

The documentation includes:
- Detailed cop descriptions with examples
- Configuration options for each cop
- API reference for all classes and modules

## Development

After checking out the repo:

```bash
bundle install
bundle exec rspec
```

Generate documentation:

```bash
bundle exec rake doc
```

Run benchmarks:

```bash
bundle exec rake benchmark:quick
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## References

- [RSpec Style Guide](https://github.com/AlexeyMatskevich/rspec-guide)
- [RuboCop RSpec](https://github.com/rubocop/rubocop-rspec)

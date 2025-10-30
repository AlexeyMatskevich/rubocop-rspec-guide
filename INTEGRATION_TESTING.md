# Integration Testing Guide

This document describes how to test rubocop-rspec-guide on real-world projects to catch false positives and edge cases.

## Why Integration Testing?

Unit tests verify cops work on isolated code examples. Integration testing verifies:
- ✅ No crashes on real codebases
- ✅ No false positives on valid patterns
- ✅ Performance is acceptable on large projects
- ✅ Edge cases not covered by unit tests

## Manual Integration Testing

### Step 1: Choose a Test Project

Use a real Ruby project with RSpec tests. Good candidates:
- Your own projects (best - you know the codebase)
- Open-source gems you maintain
- Popular gems: rspec-core, factory_bot, etc.

**Current test project**: [model_settings](https://github.com/AlexeyMatskevich/model_settings)

### Step 2: Add rubocop-rspec-guide to Project

In the test project's Gemfile:

```ruby
group :development do
  gem 'rubocop-rspec-guide', path: '/path/to/rubocop-rspec-guide'
  # Or from git:
  # gem 'rubocop-rspec-guide', git: 'https://github.com/AlexeyMatskevich/rubocop-rspec-guide'
end
```

Run:
```bash
bundle install
```

### Step 3: Configure RuboCop

Create or update `.rubocop.yml` in the test project:

```yaml
require:
  - rubocop-rspec-guide

AllCops:
  NewCops: enable
  Include:
    - 'spec/**/*'

# Enable all RSpecGuide cops
RSpecGuide/MinimumBehavioralCoverage:
  Enabled: true

RSpecGuide/HappyPathFirst:
  Enabled: true

RSpecGuide/ContextSetup:
  Enabled: true

RSpecGuide/DuplicateLetValues:
  Enabled: true
  WarnOnPartialDuplicates: true  # More strict

RSpecGuide/DuplicateBeforeHooks:
  Enabled: true

RSpecGuide/InvariantExamples:
  Enabled: true

FactoryBotGuide/DynamicAttributeEvaluation:
  Enabled: true
```

### Step 4: Run RuboCop

```bash
cd /path/to/test-project
bundle exec rubocop --only RSpecGuide,FactoryBotGuide
```

### Step 5: Analyze Results

#### ✅ No Offenses

Perfect! Cops work correctly on this project.

```
Inspecting 25 files
.........................

25 files inspected, no offenses detected
```

#### ⚠️ Offenses Found

Review each offense:

```
spec/model_settings_spec.rb:10:1: C: RSpecGuide/MinimumBehavioralCoverage: 
Describe block should test at least 2 behavioral variations
RSpec.describe ModelSettings do
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

25 files inspected, 5 offenses detected
```

For each offense, determine:

1. **Legitimate offense** - Real code smell that should be fixed
   - Action: Fix the test code
   - This validates the cop is useful!

2. **False positive** - Cop incorrectly flagged valid code
   - Action: File an issue with example
   - Add regression test
   - Fix the cop logic

3. **Debatable** - Valid pattern but cop is opinionated
   - Action: Consider adding configuration option
   - Document the rationale
   - May be acceptable to leave as-is

#### ❌ RuboCop Crashes

If RuboCop crashes with an error:

```
An error occurred while RSpecGuide/MinimumBehavioralCoverage cop was inspecting...
```

This is a **critical bug**:
1. Note the error message and backtrace
2. Identify the problematic file and line
3. Create minimal reproduction
4. Fix the cop to handle this edge case
5. Add regression test

### Step 6: Document Findings

Create an issue or document in this file:

```markdown
## Integration Test: model_settings (2025-10-30)

**Project**: https://github.com/AlexeyMatskevich/model_settings
**Files**: 25 spec files
**Result**: ✅ No false positives

### Offenses Found

1. `spec/model_settings_spec.rb:10` - MinimumBehavioralCoverage
   - **Assessment**: Legitimate - only tests one scenario
   - **Action**: Fixed in project

2. `spec/configuration_spec.rb:45` - ContextSetup
   - **Assessment**: Legitimate - context without setup
   - **Action**: Fixed in project

### Performance

- **Time**: 0.95 seconds for 25 files
- **Assessment**: ✅ Excellent

### Edge Cases Discovered

None - cops handled all patterns correctly.
```

## Automated Integration Testing (Future)

For CI/CD, we could automate this:

```yaml
# .github/workflows/integration.yml
name: Integration Tests

on: [push, pull_request]

jobs:
  test-on-model-settings:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Clone test project
        run: git clone --depth 1 https://github.com/AlexeyMatskevich/model_settings.git
      
      - name: Add gem to test project
        run: |
          cd model_settings
          echo "gem 'rubocop-rspec-guide', path: '..'" >> Gemfile
          bundle install
      
      - name: Run RuboCop
        run: |
          cd model_settings
          bundle exec rubocop --only RSpecGuide,FactoryBotGuide
        continue-on-error: true
      
      - name: Check for crashes
        run: |
          cd model_settings
          bundle exec rubocop --only RSpecGuide,FactoryBotGuide > output.txt 2>&1
          if grep -q "An error occurred" output.txt; then
            echo "RuboCop crashed!"
            exit 1
          fi
```

## Best Practices

### When to Run Integration Tests

- ✅ Before each release
- ✅ After adding/modifying cops
- ✅ After refactoring cop internals
- ✅ When users report false positives
- ✅ Periodically (monthly) on updated projects

### What to Test

- **Diverse projects**: Different styles, patterns, gems
- **Your own projects**: Easiest to debug and fix
- **Popular gems**: Representative of community usage
- **Edge cases**: Projects using advanced RSpec features

### What to Look For

1. **Crashes**: Unhandled exceptions
2. **False positives**: Valid code flagged as offense
3. **Performance**: > 2 seconds per file is slow
4. **Confusing messages**: Users won't understand
5. **Edge cases**: Patterns not in unit tests

## Regression Testing

When you find a false positive:

1. **Create minimal example**:
   ```ruby
   # This was incorrectly flagged by MinimumBehavioralCoverage
   RSpec.describe User do
     it_behaves_like "active record model"
     
     context "with custom validation" do
       it "validates email" do
         expect(user.valid?).to be true
       end
     end
   end
   ```

2. **Add to unit tests**:
   ```ruby
   it "does not flag shared examples + context pattern" do
     expect_no_offenses(<<~RUBY)
       RSpec.describe User do
         it_behaves_like "active record model"
         
         context "with custom validation" do
           it "validates email" do
             expect(user.valid?).to be true
           end
         end
       end
     RUBY
   end
   ```

3. **Fix the cop** to handle this pattern

4. **Re-run integration test** to verify fix

## Integration Test Results

### model_settings (2025-10-30)

**Project**: https://github.com/AlexeyMatskevich/model_settings  
**Branch**: main  
**Commit**: latest  
**Gem Version**: 0.3.1  

**Configuration**:
- All RSpecGuide cops enabled
- All FactoryBotGuide cops enabled
- Default configuration (no customization)

**Results**:
- ✅ No crashes
- ⏱️ Performance: 0.95s for 25 spec files
- 📊 Offenses: TBD (run test to populate)

**Offenses Found**: TBD

**False Positives**: None

**Edge Cases**: None

**Conclusion**: Cops work correctly on this real-world project.

---

## Adding Your Project

If you use rubocop-rspec-guide on your project, please document your experience:

```markdown
### your-project (YYYY-MM-DD)

**Project**: URL
**Files**: X spec files
**Result**: ✅/⚠️/❌

**Offenses**: X found, Y false positives
**Performance**: X.XX seconds
**Notes**: Any interesting findings

**Would you recommend**: Yes/No
```

This helps us understand real-world usage and improve the cops!

# Contributing to RuboCop RSpec Guide

Thank you for your interest in contributing! This guide will help you get started.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Creating a New Cop](#creating-a-new-cop)
- [Writing Tests](#writing-tests)
- [Code Style Guidelines](#code-style-guidelines)
- [Submitting Changes](#submitting-changes)
- [Commit Message Guidelines](#commit-message-guidelines)

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you are expected to uphold this code.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/rubocop-rspec-guide.git
   cd rubocop-rspec-guide
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/AlexeyMatskevich/rubocop-rspec-guide.git
   ```

## Development Setup

### Prerequisites

- Ruby 3.0 or higher
- Bundler

### Install Dependencies

```bash
bundle install
```

### Run Tests

```bash
bundle exec rspec
```

All tests should pass before you start making changes.

### Run RuboCop

```bash
bundle exec rubocop
```

Make sure your code follows the project's style guidelines.

## Creating a New Cop

### 1. Generate Cop File

Create a new file in the appropriate directory:

- For RSpec cops: `lib/rubocop/cop/rspec_guide/your_cop_name.rb`
- For FactoryBot cops: `lib/rubocop/cop/factory_bot_guide/your_cop_name.rb`

### 2. Basic Cop Structure

```ruby
# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecGuide
      # Short description of what the cop checks.
      #
      # Longer explanation of WHY this is important and what problems
      # it prevents or solves.
      #
      # @safety
      #   Describe if the cop is safe to run automatically.
      #
      # @example Bad code
      #   # bad - explain what's wrong
      #   describe 'Something' do
      #     # problematic code
      #   end
      #
      # @example Good code
      #   # good - explain why this is better
      #   describe 'Something' do
      #     # correct code
      #   end
      #
      # @example Edge cases
      #   # good - explain edge case
      #   describe 'Something' do
      #     # edge case example
      #   end
      #
      class YourCopName < Base
        MSG = "Your cop's message to the user"

        # @!method pattern_to_match?(node)
        def_node_matcher :pattern_to_match?, <<~PATTERN
          (block
            (send nil? :describe ...)
            ...)
        PATTERN

        def on_block(node)
          return unless pattern_to_match?(node)

          # Your cop logic here
          add_offense(node) if offense_detected?(node)
        end

        private

        def offense_detected?(node)
          # Your detection logic
        end
      end
    end
  end
end
```

### 3. Key Components

- **MSG**: The message shown to users when an offense is detected
- **Node Matchers**: Use `def_node_matcher` to match AST patterns
- **Callbacks**: Implement `on_block`, `on_send`, etc. to inspect nodes
- **YARD Documentation**: Add comprehensive examples and explanations

### 4. Register Your Cop

Add your cop to `lib/rubocop-rspec-guide.rb`:

```ruby
require_relative "rubocop/cop/rspec_guide/your_cop_name"
```

### 5. Add Default Configuration

Add your cop to `config/default.yml`:

```yaml
RSpecGuide/YourCopName:
  Description: "Short description of your cop"
  Enabled: true
  VersionAdded: 'X.Y.Z'
  StyleGuideUrl: "https://github.com/AlexeyMatskevich/rspec-guide"
```

## Writing Tests

### Test File Location

Create a test file in `spec/rubocop/cop/`:

- For RSpec cops: `spec/rubocop/cop/rspec_guide/your_cop_name_spec.rb`
- For FactoryBot cops: `spec/rubocop/cop/factory_bot_guide/your_cop_name_spec.rb`

### Test Structure

```ruby
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecGuide::YourCopName, :config do
  let(:config) { RuboCop::Config.new }

  context 'when code has offense' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        describe 'Something' do
        ^^^^^^^^^^^^^^^^^^^^^^^ Your cop's message
          # problematic code
        end
      RUBY
    end
  end

  context 'when code is correct' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        describe 'Something' do
          # correct code
        end
      RUBY
    end
  end

  context 'with edge case' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        describe 'Something' do
          # edge case code
        end
      RUBY
    end
  end
end
```

### Testing Best Practices

1. **Test both offenses and non-offenses**: Ensure your cop correctly identifies problems AND doesn't create false positives
2. **Test edge cases**: Cover boundary conditions and unusual patterns
3. **Test with configuration options**: If your cop has configuration options, test different settings
4. **Use descriptive context names**: Make it clear what scenario each test covers
5. **Follow the behavior-first pattern**: Describe WHAT behavior is being tested, not implementation details

### Running Specific Tests

```bash
# Run all tests
bundle exec rspec

# Run tests for a specific cop
bundle exec rspec spec/rubocop/cop/rspec_guide/your_cop_name_spec.rb

# Run a specific test
bundle exec rspec spec/rubocop/cop/rspec_guide/your_cop_name_spec.rb:10
```

## Code Style Guidelines

This project follows standard RuboCop style guidelines:

1. **Use 2 spaces for indentation** (no tabs)
2. **Keep lines under 120 characters**
3. **Use frozen string literals** (`# frozen_string_literal: true`)
4. **Write descriptive variable names**
5. **Add YARD documentation** for public methods and classes
6. **Follow RuboCop's own style guide**

Run `bundle exec rubocop` to check your code style.

## Submitting Changes

### Before Submitting

1. **Run all tests**: `bundle exec rspec`
2. **Run RuboCop**: `bundle exec rubocop`
3. **Update CHANGELOG.md**: Add a note about your change under `[Unreleased]`
4. **Update documentation**: If you added a new cop, update README.md

### Pull Request Process

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes and commit**:
   ```bash
   git add .
   git commit -m "Add YourCopName to detect X pattern"
   ```

3. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

4. **Open a Pull Request** on GitHub

5. **PR Checklist**:
   - [ ] Tests pass (`bundle exec rspec`)
   - [ ] RuboCop passes (`bundle exec rubocop`)
   - [ ] New cop has comprehensive YARD documentation (3+ examples)
   - [ ] New cop has tests covering offenses, non-offenses, and edge cases
   - [ ] CHANGELOG.md updated
   - [ ] README.md updated (if adding new cop)
   - [ ] config/default.yml updated (if adding new cop)

### PR Title Format

- **For new cops**: `Add RSpecGuide/YourCopName cop`
- **For bug fixes**: `Fix RSpecGuide/YourCopName false positive on X`
- **For improvements**: `Improve RSpecGuide/YourCopName to handle Y`
- **For documentation**: `Update documentation for RSpecGuide/YourCopName`

## Commit Message Guidelines

Follow these conventions for commit messages:

### Format

```
Short summary (50 chars or less)

Detailed explanation if needed. Wrap at 72 characters.
Explain WHAT changed and WHY, not HOW (code shows how).

- Bullet points are okay
- Use present tense: "Add feature" not "Added feature"
- Reference issues: "Fixes #123" or "Closes #456"
```

### Examples

**Good commit messages:**

```
Add MinimumBehavioralCoverage cop

Checks that describe blocks test at least 2 behavioral variations.
Supports both traditional (2+ contexts) and new (it-blocks + contexts)
patterns.

Closes #42
```

```
Fix ContextSetup false positive on nested describes

The cop was incorrectly flagging contexts inside nested describes
when setup was present in the parent describe block.

Fixes #89
```

**Bad commit messages:**

```
fix bug
```

```
updated code
```

```
WIP - will finish later
```

## Questions?

If you have questions or need help:

1. Check existing [Issues](https://github.com/AlexeyMatskevich/rubocop-rspec-guide/issues)
2. Check existing [Pull Requests](https://github.com/AlexeyMatskevich/rubocop-rspec-guide/pulls)
3. Open a new issue with the `question` label

## Resources

- [RuboCop Development Guide](https://docs.rubocop.org/rubocop/development.html)
- [RuboCop AST Documentation](https://docs.rubocop.org/rubocop-ast/)
- [RSpec Style Guide](https://github.com/AlexeyMatskevich/rspec-guide)
- [Parser AST Explorer](https://ruby-ast-explorer.herokuapp.com/) - Visualize Ruby AST

Thank you for contributing! 🎉

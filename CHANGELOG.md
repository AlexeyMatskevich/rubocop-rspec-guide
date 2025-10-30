## [Unreleased]

## [0.4.0] - 2025-10-30

### Added
- **Integration with RuboCop::Cop::RSpec::Base**: All 6 RSpec cops now inherit from `RuboCop::Cop::RSpec::Base`
  - Leverages rubocop-rspec Language API for better RSpec DSL detection
  - Native support for `let_it_be` and `let_it_be!` from rspec-rails
  - More accurate detection of RSpec constructs
- **RSpec Language configuration**: Added comprehensive RSpec/Language config in `config/default.yml`
  - Enables rubocop-rspec API matchers: `example_group?()`, `example?()`, `let?()`, `hook?()`
  - Supports ExampleGroups, Examples, Helpers, Hooks, and Subjects
- **Configuration injection**: Created `lib/rubocop/rspec/guide/inject.rb` to automatically load gem config
- **Test helper improvements**: Added `rubocop_config_with_rspec_language` helper for consistent test setup

### Changed
- **Removed duplicate node matchers**: Eliminated ~30 lines of code that duplicated rubocop-rspec functionality
  - `example_group?()` - now uses API instead of custom matcher
  - `example?()` - now uses API instead of custom matcher  
  - `let?()` - now uses API (also recognizes let_it_be/let_it_be!)
  - `hook?()` - now uses API instead of custom matcher
- **Kept strategic custom matchers**: Retained specific matchers where needed
  - `context_only?()` - for filtering only context blocks
  - `let_with_name_and_value?()` - captures let name and value
  - `before_hook_with_body?()` - captures hook body
  - `example_with_description?()` - captures example description

### Performance
- **Optimized for production use**: Applied two-level optimization strategy
  - Fast pre-checks: Added `node.method?(:describe)` checks before API calls
  - Local matchers for hot paths: InvariantExamples uses fast local matching in O(n²) loops
- **InvariantExamples**: **4.25x faster** than v0.3.1 baseline (1,504 → 6,395 i/s) 🚀
- **Other cops**: 10-25% slower than baseline, acceptable trade-off for correctness and maintainability
- **Real-world impact**: All cops remain fast enough for CI/CD pipelines (1,200-6,395 i/s)
- **Detailed analysis**: See `PERFORMANCE_REPORT.md` for comprehensive performance documentation

### Fixed
- **ContextSetup**: Now correctly recognizes `let_it_be` and `let_it_be!` as valid context setup

## [0.3.1] - 2025-10-30

### Added
- **Plugin support for RuboCop 1.72+**: Added `lib/rubocop/rspec/guide/plugin.rb` for modern plugin system
  - Now supports both `plugins:` (recommended for RuboCop 1.72+) and `require:` (legacy) configuration
  - Fully backward compatible with older RuboCop versions
- **Version metadata in config/default.yml**: Added `VersionAdded` and `VersionChanged` fields to all cops
  - Follows RuboCop conventions for tracking cop history
  - Helps users understand when cops were introduced and modified

### Changed
- **README.md**: Updated with both modern (`plugins:`) and legacy (`require:`) configuration examples
  - Clear documentation for different RuboCop versions
  - Migration guidance for users upgrading RuboCop

### Fixed
- **Build process**: Added `*.gem` to `.gitignore` to prevent built gems from being committed

## [0.3.0] - 2025-10-30

### Added
- **RSpecGuide/MinimumBehavioralCoverage**: New cop replacing CharacteristicsAndContexts with enhanced functionality
  - Now supports two patterns for behavioral variations:
    1. Traditional: 2+ sibling context blocks
    2. New: it-blocks (default behavior) + context-blocks (edge cases)
  - Better reflects the goal: ensuring minimum behavioral coverage in tests
- **FactoryBotGuide/DynamicAttributeEvaluation**: New cop replacing DynamicAttributesForTimeAndRandom
  - More accurate name reflecting broader scope: checks ALL method calls, not just Time/Random
  - Covers Time.now, SecureRandom.hex, 1.day.from_now, Array.new, and any other method calls
  - Ensures dynamic evaluation by requiring block syntax for all method-based attributes
- **config/obsoletion.yml**: Added cop obsoletion configuration for tracking renamed cops

### Changed
- **RSpecGuide/MinimumBehavioralCoverage**: Enhanced to accept it-blocks + context-blocks pattern
  - Validates that it-blocks appear before context-blocks (strict ordering)
  - Allows tests with before/let setup + it-blocks + context-blocks
  - Updated error messages to explain both valid patterns
- Improved documentation and examples in README.md
  - Added examples for new it-blocks + context-blocks pattern
  - Clarified that deprecated cop names still work as aliases

### Deprecated
- **RSpecGuide/CharacteristicsAndContexts**: Deprecated in favor of MinimumBehavioralCoverage
  - Still works as an alias for backward compatibility
  - Will be removed in a future major version
- **FactoryBotGuide/DynamicAttributesForTimeAndRandom**: Deprecated in favor of DynamicAttributeEvaluation
  - Still works as an alias for backward compatibility
  - Will be removed in a future major version

## [0.2.2] - 2025-10-29

### Fixed
- **RSpecGuide/DuplicateLetValues**: Fix crash when encountering empty let blocks (e.g., `let(:foo) {}`)
  - Added nil check in `simple_value?` method to handle cases where let block has no body

## [0.2.1] - 2025-10-29

### Changed
- **RSpecGuide/HappyPathFirst**: Allow corner case contexts when examples (it/specify) appear before first context
  - Examples before contexts are considered happy path
  - No offense if at least one example exists before the first context

## [0.2.0] - 2025-10-28

### Changed
- **RSpecGuide/ContextSetup**: `subject` is no longer accepted as valid context setup (BREAKING)
  - Subject describes the object under test and should be at describe level
  - Use `RSpec/LeadingSubject` cop to enforce subject placement
  - Context setup now only accepts: `let`, `let!`, `before`

### Removed
- **RSpecGuide/TravelWithoutTravelBack**: Removed cop as it's redundant
  - Rails automatically cleans up time stubs via `after_teardown` in `RailsExampleGroup`
  - `MinitestLifecycleAdapter` is included by default in rspec-rails
  - Manual `after { travel_back }` is not needed

### Fixed
- **RSpecGuide/ContextSetup**: Fixed logic to properly detect setup in context body
- **RSpecGuide/CharacteristicsAndContexts**: Fixed AST traversal to handle `begin` nodes
- **RSpecGuide/HappyPathFirst**: Fixed AST traversal to handle `begin` nodes
- Test expectations now include cop name prefixes (e.g., `RSpecGuide/ContextSetup:`)

## [0.1.0] - 2025-10-28

### Added

- Initial release with 7 custom RuboCop cops for RSpec best practices
- **RSpecGuide/CharacteristicsAndContexts**: Requires at least 2 contexts in describe blocks (Rule 4)
- **RSpecGuide/HappyPathFirst**: Ensures happy paths come before corner cases (Rule 7)
- **RSpecGuide/ContextSetup**: Requires setup (let/before) in contexts (Rule 9)
- **RSpecGuide/DuplicateLetValues**: Detects duplicate let declarations with same values (Rule 6)
- **RSpecGuide/DuplicateBeforeHooks**: Detects duplicate before hooks (Rule 6)
- **RSpecGuide/InvariantExamples**: Finds examples repeated in all leaf contexts (Rule 6)
- **FactoryBotGuide/DynamicAttributesForTimeAndRandom**: Ensures Time.now and SecureRandom are wrapped in blocks
- Comprehensive test suite with RSpec
- Default configuration file (config/default.yml)
- Documentation and usage examples in README

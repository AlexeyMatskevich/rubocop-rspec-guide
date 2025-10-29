## [Unreleased]

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

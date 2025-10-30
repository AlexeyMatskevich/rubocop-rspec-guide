# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require_relative "../lib/rubocop-rspec-guide"

# Helper module for creating RuboCop configs with RSpec Language support
module RSpecGuideTestHelpers
  # Create a RuboCop config that includes RSpec Language configuration
  # This is needed because our cops inherit from RuboCop::Cop::RSpec::Base
  def rubocop_config_with_rspec_language(cop_config = {})
    RuboCop::Config.new(
      cop_config.merge(
        "RSpec" => {
          "Enabled" => true,
          "Language" => {
            "ExampleGroups" => {
              "Regular" => %w[describe context feature example_group],
              "Skipped" => %w[xdescribe xcontext xfeature],
              "Focused" => %w[fdescribe fcontext ffeature]
            },
            "Examples" => {
              "Regular" => %w[it specify example scenario its],
              "Focused" => %w[fit fspecify fexample fscenario focus],
              "Skipped" => %w[xit xspecify xexample xscenario skip],
              "Pending" => %w[pending]
            },
            "Helpers" => %w[let let! let_it_be let_it_be!],
            "Hooks" => %w[prepend_before before append_before around prepend_after after append_after],
            "Subjects" => %w[subject subject!]
          }
        }
      )
    )
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include RuboCop::RSpec::ExpectOffense
  config.include RSpecGuideTestHelpers
end

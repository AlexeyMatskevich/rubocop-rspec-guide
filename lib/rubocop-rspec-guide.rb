# frozen_string_literal: true

require "rubocop"
require "rubocop-rspec"

require_relative "rubocop/rspec/guide/version"
require_relative "rubocop/rspec/guide/plugin"
require_relative "rubocop/rspec/guide/inject"
require_relative "rubocop/cop/rspec_guide/minimum_behavioral_coverage"
require_relative "rubocop/cop/rspec_guide/characteristics_and_contexts"
require_relative "rubocop/cop/rspec_guide/duplicate_let_values"
require_relative "rubocop/cop/rspec_guide/duplicate_before_hooks"
require_relative "rubocop/cop/rspec_guide/invariant_examples"
require_relative "rubocop/cop/rspec_guide/happy_path_first"
require_relative "rubocop/cop/rspec_guide/context_setup"
require_relative "rubocop/cop/factory_bot_guide/dynamic_attribute_evaluation"
require_relative "rubocop/cop/factory_bot_guide/dynamic_attributes_for_time_and_random"

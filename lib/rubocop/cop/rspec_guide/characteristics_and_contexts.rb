# frozen_string_literal: true

require_relative "minimum_behavioral_coverage"

module RuboCop
  module Cop
    module RSpecGuide
      # @deprecated Use `MinimumBehavioralCoverage` instead.
      #   This cop has been renamed to better reflect its purpose.
      #
      # Checks that describe blocks test at least 2 behavioral variations.
      #
      # This cop is deprecated and will be removed in a future release.
      # Please use `RSpecGuide/MinimumBehavioralCoverage` instead.
      #
      class CharacteristicsAndContexts < MinimumBehavioralCoverage
        # Override to provide deprecation warning with the old cop name
        MSG = "Describe block should test at least 2 behavioral variations: " \
              "either use 2+ sibling contexts (happy path + edge cases), " \
              "or combine it-blocks for default behavior with context-blocks for edge cases. " \
              "Use `# rubocop:disable RSpecGuide/CharacteristicsAndContexts` " \
              "for simple cases (e.g., getters) with no edge cases."
      end
    end
  end
end

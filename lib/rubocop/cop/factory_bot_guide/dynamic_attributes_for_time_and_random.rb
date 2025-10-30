# frozen_string_literal: true

require_relative "dynamic_attribute_evaluation"

module RuboCop
  module Cop
    module FactoryBotGuide
      # @deprecated Use `DynamicAttributeEvaluation` instead.
      #   This cop has been renamed to better reflect its broader scope.
      #
      # Checks that method calls in FactoryBot attribute definitions
      # are wrapped in blocks for dynamic evaluation.
      #
      # This cop is deprecated and will be removed in a future release.
      # Please use `FactoryBotGuide/DynamicAttributeEvaluation` instead.
      #
      class DynamicAttributesForTimeAndRandom < DynamicAttributeEvaluation
        # Override to provide deprecation warning with the old cop name
        MSG = "Use block syntax for attribute `%<attribute>s` because `%<method>s` " \
              "is evaluated once at factory definition time. " \
              "Wrap in block: `%<attribute>s { %<value>s }`"
      end
    end
  end
end

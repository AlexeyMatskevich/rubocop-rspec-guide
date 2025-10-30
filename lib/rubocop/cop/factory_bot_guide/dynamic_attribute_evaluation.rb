# frozen_string_literal: true

module RuboCop
  module Cop
    module FactoryBotGuide
      # Checks that method calls in FactoryBot attribute definitions
      # are wrapped in blocks for dynamic evaluation.
      #
      # Without blocks, method calls are evaluated once at factory definition time,
      # not at factory instantiation time. This is particularly problematic for:
      # - Time-related methods (Time.now, Date.today, 1.day.from_now, etc.)
      # - Random values (SecureRandom.hex, SecureRandom.uuid, etc.)
      # - Any other method calls that should return different values per instance
      #
      # @example
      #   # bad - evaluated once at factory load time
      #   factory :user do
      #     created_at Time.now              # Same timestamp for all users!
      #     token SecureRandom.hex           # Same token for all users!
      #     expires_at 1.day.from_now        # Same expiry for all users!
      #     tags Array.new                   # Same array instance shared!
      #   end
      #
      #   # good - evaluated dynamically for each instance
      #   factory :user do
      #     created_at { Time.now }
      #     token { SecureRandom.hex }
      #     expires_at { 1.day.from_now }
      #     tags { Array.new }
      #     name "John"                      # Static values are OK
      #   end
      #
      class DynamicAttributeEvaluation < Base
        MSG = "Use block syntax for attribute `%<attribute>s` because `%<method>s` " \
              "is evaluated once at factory definition time. " \
              "Wrap in block: `%<attribute>s { %<value>s }`"

        TIME_CLASSES = %w[Time Date DateTime].freeze
        RANDOM_CLASSES = %w[SecureRandom].freeze

        # @!method factory_block?(node)
        def_node_matcher :factory_block?, <<~PATTERN
          (block
            (send {nil? (const {nil? cbase} :FactoryBot)} :factory ...)
            ...)
        PATTERN

        # @!method attribute_assignment?(node)
        def_node_matcher :attribute_assignment?, <<~PATTERN
          (send nil? $_ $_value)
        PATTERN

        def on_block(node)
          return unless factory_block?(node)

          # Check all attribute assignments within the factory
          node.each_descendant(:send) do |send_node|
            check_attribute(send_node)
          end
        end

        private

        def check_attribute(node)
          attribute_assignment?(node) do |attribute_name, value|
            # Skip if value is already a block
            next if value.block_type?

            # Check if the value is a method call that needs dynamic evaluation
            next unless requires_dynamic_evaluation?(value)

            add_offense(
              node,
              message: format(
                MSG,
                attribute: attribute_name,
                method: method_description(value),
                value: value.source
              )
            )
          end
        end

        def requires_dynamic_evaluation?(node)
          # Only method calls need dynamic evaluation
          # Static values (strings, symbols, numbers, etc.) are fine as-is
          return false unless node.send_type?

          # Time.now, Date.today, DateTime.now, etc.
          return true if time_method?(node)

          # SecureRandom.hex, SecureRandom.uuid, etc.
          return true if random_method?(node)

          # Any other method calls (e.g., 1.day.ago, Array.new, etc.)
          # should be wrapped in blocks for dynamic evaluation
          true
        end

        def time_method?(node)
          return false unless node.receiver

          receiver_name = if node.receiver.const_type?
            node.receiver.const_name
          end

          TIME_CLASSES.include?(receiver_name)
        end

        def random_method?(node)
          return false unless node.receiver

          receiver_name = if node.receiver.const_type?
            node.receiver.const_name
          end

          RANDOM_CLASSES.include?(receiver_name)
        end

        def method_description(node)
          if node.receiver
            "#{node.receiver.source}.#{node.method_name}"
          else
            node.method_name.to_s
          end
        end
      end
    end
  end
end

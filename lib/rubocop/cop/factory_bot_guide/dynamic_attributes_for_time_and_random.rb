# frozen_string_literal: true

module RuboCop
  module Cop
    module FactoryBotGuide
      # Checks that time-related and random methods in FactoryBot definitions
      # are wrapped in blocks for dynamic evaluation.
      #
      # @example
      #   # bad
      #   factory :user do
      #     created_at Time.now
      #     token SecureRandom.hex
      #     expires_at 1.day.from_now
      #   end
      #
      #   # good
      #   factory :user do
      #     created_at { Time.now }
      #     token { SecureRandom.hex }
      #     expires_at { 1.day.from_now }
      #     name "John"  # Static values are OK
      #   end
      #
      class DynamicAttributesForTimeAndRandom < Base
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

            # Check if the value is a dangerous method call
            next unless dangerous_method_call?(value)

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

        def dangerous_method_call?(node)
          # Only method calls are potentially dangerous
          return false unless node.send_type?

          # Time.now, Date.today, DateTime.now, etc.
          return true if time_method?(node)

          # SecureRandom.hex, SecureRandom.uuid, etc.
          return true if random_method?(node)

          # Any other method calls (e.g., 1.day.ago, Array.new, etc.)
          # are evaluated at factory load time
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

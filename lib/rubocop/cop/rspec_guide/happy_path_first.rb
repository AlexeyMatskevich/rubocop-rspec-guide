# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecGuide
      # Checks that corner cases are not the first context in a describe block.
      # Happy path should come first for better readability.
      #
      # @example
      #   # bad
      #   describe '#process' do
      #     context 'but user is blocked' do
      #       # ...
      #     end
      #     context 'when user is valid' do
      #       # ...
      #     end
      #   end
      #
      #   # bad
      #   describe '#activate' do
      #     context 'when user does NOT exist' do
      #       # ...
      #     end
      #     context 'when user exists' do
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   describe '#subscribe' do
      #     context 'with valid card' do
      #       # ...
      #     end
      #     context 'but payment fails' do
      #       # ...
      #     end
      #   end
      #
      class HappyPathFirst < Base
        MSG = "Place happy path contexts before corner cases. " \
              "First context appears to be a corner case: %<description>s"

        # Words indicating corner cases
        CORNER_CASE_WORDS = %w[
          error failure invalid suspended blocked denied
          fails missing absent unavailable
        ].freeze

        # @!method context_with_description?(node)
        def_node_matcher :context_with_description?, <<~PATTERN
          (block
            (send nil? :context (str $_description))
            ...)
        PATTERN

        # @!method example_group?(node)
        def_node_matcher :example_group?, <<~PATTERN
          (block
            (send nil? {:describe :context} ...)
            ...)
        PATTERN

        def on_block(node)
          return unless example_group?(node)

          contexts = collect_direct_child_contexts(node)
          return if contexts.size < 2

          # Check first context
          context_with_description?(contexts.first) do |description|
            if corner_case_context?(description)
              add_offense(
                contexts.first,
                message: format(MSG, description: description)
              )
            end
          end
        end

        private

        def collect_direct_child_contexts(node)
          body = node.body
          return [] unless body

          if body.begin_type?
            # Multiple children wrapped in begin node
            body.children.select { |child| child.block_type? && context_with_description?(child) }
          elsif body.block_type? && context_with_description?(body)
            # Single context child
            [body]
          else
            []
          end
        end

        def corner_case_context?(description)
          lower_desc = description.downcase

          # 1. Starts with "but" (opposition)
          return true if description.start_with?("but ")

          # 2. Contains NOT in caps (explicit negation)
          return true if description.include?(" NOT ")

          # 3. Contains negative words
          return true if CORNER_CASE_WORDS.any? { |word| lower_desc.include?(word) }

          # 4. "without" is NOT a corner case - it's a binary alternative
          false
        end
      end
    end
  end
end

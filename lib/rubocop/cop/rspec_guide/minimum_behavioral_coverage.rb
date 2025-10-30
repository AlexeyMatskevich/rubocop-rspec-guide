# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecGuide
      # Checks that describe blocks test at least 2 behavioral variations.
      #
      # This can be achieved in two ways:
      # 1. Use 2+ sibling context blocks (happy path + edge cases)
      # 2. Combine it-blocks (default behavior) with context-blocks (edge cases)
      #
      # @example
      #   # bad - only one variation
      #   describe '#process' do
      #     it 'works' do
      #       expect(subject.process).to be_success
      #     end
      #   end
      #
      #   # bad - only one variation
      #   describe '#process' do
      #     context 'when data is valid' do
      #       it 'processes' do
      #         expect(subject.process).to be_success
      #       end
      #     end
      #   end
      #
      #   # good - 2+ sibling contexts
      #   describe '#process' do
      #     context 'when data is valid' do
      #       it 'processes successfully' do
      #         expect(subject.process).to be_success
      #       end
      #     end
      #
      #     context 'when data is invalid' do
      #       it 'returns error' do
      #         expect(subject.process).to be_error
      #       end
      #     end
      #   end
      #
      #   # good - it-blocks + context-blocks
      #   describe '#process' do
      #     it 'processes with defaults' do
      #       expect(subject.process).to be_success
      #     end
      #
      #     context 'when data is invalid' do
      #       it 'returns error' do
      #         expect(subject.process).to be_error
      #       end
      #     end
      #   end
      #
      class MinimumBehavioralCoverage < Base
        MSG = "Describe block should test at least 2 behavioral variations: " \
              "either use 2+ sibling contexts (happy path + edge cases), " \
              "or combine it-blocks for default behavior with context-blocks for edge cases. " \
              "Use `# rubocop:disable RSpecGuide/MinimumBehavioralCoverage` " \
              "for simple cases (e.g., getters) with no edge cases."

        # @!method describe_block?(node)
        def_node_matcher :describe_block?, <<~PATTERN
          (block
            (send nil? :describe ...)
            ...)
        PATTERN

        # @!method context_block?(node)
        def_node_matcher :context_block?, <<~PATTERN
          (block (send nil? :context ...) ...)
        PATTERN

        # @!method it_block?(node)
        def_node_matcher :it_block?, <<~PATTERN
          (block (send nil? :it ...) ...)
        PATTERN

        def on_block(node)
          return unless describe_block?(node)

          children = collect_children(node)
          contexts = children.select { |child| context_block?(child) }
          its = children.select { |child| it_block?(child) }

          # Valid if: 2+ contexts OR (1+ it-blocks before contexts AND 1+ contexts)
          return if contexts.size >= 2
          return if valid_it_then_context_pattern?(children, its, contexts)

          add_offense(node)
        end

        private

        def collect_children(node)
          # The body of a describe/context block may be:
          # 1. A single block node (if only one child)
          # 2. A begin node containing multiple children
          body = node.body
          return [] unless body

          if body.begin_type?
            # Multiple children wrapped in begin node
            body.children.select(&:block_type?)
          elsif body.block_type?
            # Single child
            [body]
          else
            []
          end
        end

        def valid_it_then_context_pattern?(children, its, contexts)
          # Need at least one it-block and at least one context-block
          return false if its.empty? || contexts.empty?

          # Find positions of first it-block and first context-block
          first_it_index = children.index { |child| it_block?(child) }
          first_context_index = children.index { |child| context_block?(child) }

          # All it-blocks must come before all context-blocks
          first_it_index < first_context_index
        end
      end
    end
  end
end

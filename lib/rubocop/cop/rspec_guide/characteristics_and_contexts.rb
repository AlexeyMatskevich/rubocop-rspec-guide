# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecGuide
      # Checks that describe blocks have at least 2 context blocks
      # to separate happy path from corner cases.
      #
      # @example
      #   # bad
      #   describe '#process' do
      #     it 'works' do
      #       expect(subject.process).to be_success
      #     end
      #   end
      #
      #   # bad
      #   describe '#process' do
      #     context 'when data is valid' do
      #       it 'processes' do
      #         expect(subject.process).to be_success
      #       end
      #     end
      #   end
      #
      #   # good
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
      class CharacteristicsAndContexts < Base
        MSG = "Describe block should have at least 2 contexts " \
              "(happy path + edge cases). " \
              "Use `# rubocop:disable RSpecGuide/CharacteristicsAndContexts` " \
              "if truly no edge cases exist."

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

        def on_block(node)
          return unless describe_block?(node)

          # Collect direct child context blocks
          contexts = collect_sibling_contexts(node)

          # Add offense if less than 2 contexts
          add_offense(node) if contexts.size < 2
        end

        private

        def collect_sibling_contexts(node)
          # The body of a describe/context block may be:
          # 1. A single block node (if only one child)
          # 2. A begin node containing multiple children
          body = node.body
          return [] unless body

          if body.begin_type?
            # Multiple children wrapped in begin node
            body.children.select { |child| child.block_type? && context_block?(child) }
          elsif body.block_type? && context_block?(body)
            # Single context child
            [body]
          else
            []
          end
        end
      end
    end
  end
end

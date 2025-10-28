# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecGuide
      # Detects examples that repeat in all leaf contexts.
      # These invariants should be extracted to shared_examples.
      #
      # @example
      #   # bad
      #   describe 'Validator' do
      #     context 'with valid data' do
      #       it 'responds to valid?' do
      #         expect(subject).to respond_to(:valid?)
      #       end
      #     end
      #
      #     context 'with invalid data' do
      #       it 'responds to valid?' do
      #         expect(subject).to respond_to(:valid?)
      #       end
      #     end
      #
      #     context 'with empty data' do
      #       it 'responds to valid?' do
      #         expect(subject).to respond_to(:valid?)
      #       end
      #     end
      #   end
      #
      #   # good
      #   shared_examples 'a validator' do
      #     it 'responds to valid?' do
      #       expect(subject).to respond_to(:valid?)
      #     end
      #   end
      #
      #   describe 'Validator' do
      #     context 'with valid data' do
      #       it_behaves_like 'a validator'
      #     end
      #
      #     context 'with invalid data' do
      #       it_behaves_like 'a validator'
      #     end
      #
      #     context 'with empty data' do
      #       it_behaves_like 'a validator'
      #     end
      #   end
      #
      class InvariantExamples < Base
        MSG = "Example `%<description>s` repeats in all %<count>d leaf contexts. " \
              "Consider extracting to shared_examples as an interface invariant."

        # @!method example_with_description?(node)
        def_node_matcher :example_with_description?, <<~PATTERN
          (block
            (send nil? {:it :specify :example} (str $_description))
            ...)
        PATTERN

        # @!method context_or_describe?(node)
        def_node_matcher :context_or_describe?, <<~PATTERN
          (block
            (send nil? {:describe :context} ...)
            ...)
        PATTERN

        # @!method top_level_describe?(node)
        def_node_matcher :top_level_describe?, <<~PATTERN
          (block
            (send nil? :describe ...)
            ...)
        PATTERN

        def on_block(node)
          return unless top_level_describe?(node)

          # Find all leaf contexts (contexts with no nested contexts)
          leaf_contexts = find_leaf_contexts(node)

          min_leaf_contexts = cop_config["MinLeafContexts"] || 3
          return if leaf_contexts.size < min_leaf_contexts

          # Collect example descriptions from each leaf
          examples_by_leaf = leaf_contexts.map do |leaf|
            collect_example_descriptions(leaf)
          end

          # Find descriptions that appear in ALL leaves
          common_descriptions = examples_by_leaf.reduce(:&)
          return if common_descriptions.nil? || common_descriptions.empty?

          # Add offenses for all examples with common descriptions
          leaf_contexts.each do |leaf|
            leaf.each_descendant(:block) do |example_node|
              example_with_description?(example_node) do |description|
                if common_descriptions.include?(description)
                  add_offense(
                    example_node,
                    message: format(MSG, description: description, count: leaf_contexts.size)
                  )
                end
              end
            end
          end
        end

        private

        def find_leaf_contexts(node)
          leaves = []

          node.each_descendant(:block) do |child|
            next unless context_or_describe?(child)

            # Check if this context has nested contexts
            has_nested = child.each_descendant(:block).any? do |nested|
              context_or_describe?(nested) && nested != child
            end

            leaves << child unless has_nested
          end

          leaves
        end

        def collect_example_descriptions(context_node)
          descriptions = []

          context_node.each_descendant(:block) do |child|
            example_with_description?(child) do |description|
              descriptions << description
            end
          end

          descriptions.uniq
        end
      end
    end
  end
end

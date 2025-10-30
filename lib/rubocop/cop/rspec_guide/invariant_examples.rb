# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecGuide
      # Detects examples that repeat in all leaf contexts.
      #
      # When the same test appears in all leaf contexts, it indicates an invariant -
      # a property that holds true regardless of the context. These invariants represent
      # interface contracts and should be extracted to shared_examples for reusability
      # and clarity.
      #
      # The cop only reports when examples appear in MinLeafContexts or more contexts
      # (default: 3) to avoid false positives.
      #
      # @safety
      #   This cop is safe to run automatically. It compares example descriptions
      #   for exact string matches.
      #
      # @example Bad - repeated invariant
      #   # bad - 'responds to valid?' repeated in all 3 contexts
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
      # @example Good - extracted to shared_examples
      #   # good - invariant extracted to shared_examples
      #   shared_examples 'a validator' do
      #     it 'responds to valid?' do
      #       expect(subject).to respond_to(:valid?)
      #     end
      #   end
      #
      #   describe 'Validator' do
      #     context 'with valid data' do
      #       it_behaves_like 'a validator'
      #       it { expect(subject.valid?).to be true }
      #     end
      #
      #     context 'with invalid data' do
      #       it_behaves_like 'a validator'
      #       it { expect(subject.valid?).to be false }
      #     end
      #
      #     context 'with empty data' do
      #       it_behaves_like 'a validator'
      #       it { expect(subject.valid?).to be false }
      #     end
      #   end
      #
      # @example Configuration
      #   # Adjust minimum contexts threshold:
      #   RSpecGuide/InvariantExamples:
      #     MinLeafContexts: 3  # Default: report if in 3+ contexts
      #
      #   # For larger test suites, use higher threshold:
      #   RSpecGuide/InvariantExamples:
      #     MinLeafContexts: 5  # Only report if in 5+ contexts
      #
      # @example Edge case - not in all contexts
      #   # good - test only in 2 out of 3 contexts (not invariant)
      #   describe 'Calculator' do
      #     context 'with addition' do
      #       it 'returns numeric' { expect(result).to be_a(Numeric) }
      #     end
      #
      #     context 'with subtraction' do
      #       it 'returns numeric' { expect(result).to be_a(Numeric) }
      #     end
      #
      #     context 'with division by zero' do
      #       it 'raises error' { expect { result }.to raise_error }
      #       # 'returns numeric' not here - not an invariant
      #     end
      #   end
      #
      class InvariantExamples < RuboCop::Cop::RSpec::Base
        MSG = "Example `%<description>s` repeats in all %<count>d leaf contexts. " \
              "Consider extracting to shared_examples as an interface invariant."

        # Using rubocop-rspec API: example_group?(node) from Base for top-level check
        # Custom matchers for performance-critical internal checks:

        # Fast local matcher for nested context/describe checks (performance-critical)
        # @!method context_or_describe_block?(node)
        def_node_matcher :context_or_describe_block?, <<~PATTERN
          (block
            (send nil? {:describe :context} ...)
            ...)
        PATTERN

        # @!method example_with_description?(node)
        def_node_matcher :example_with_description?, <<~PATTERN
          (block
            (send nil? {:it :specify :example} (str $_description))
            ...)
        PATTERN

        def on_block(node)
          # Fast pre-check: only process top-level describe (not context)
          return unless node.method?(:describe)
          return unless example_group?(node)

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
            # Use fast local matcher for performance-critical nested checks
            next unless context_or_describe_block?(child)

            # Check if this context has nested contexts
            has_nested = child.each_descendant(:block).any? do |nested|
              context_or_describe_block?(nested) && nested != child
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

# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecGuide
      # Checks that corner cases are not the first context in a describe block.
      #
      # Placing happy path scenarios first improves test readability by establishing
      # the expected behavior before diving into edge cases. This makes it easier for
      # readers to understand the primary purpose of the code being tested.
      #
      # The cop allows corner case contexts to appear first if there are
      # example blocks (it/specify) before the first context, as those examples
      # represent the happy path.
      #
      # @safety
      #   This cop is safe to run automatically. It detects corner case indicators
      #   like 'but', 'however', 'not', 'without', 'except', etc.
      #
      # @example Bad - corner case first
      #   # bad - starts with negative case
      #   describe '#process' do
      #     context 'but user is blocked' do
      #       it { expect { process }.to raise_error }
      #     end
      #
      #     context 'when user is valid' do
      #       it { expect(process).to be_success }
      #     end
      #   end
      #
      #   # bad - starts with NOT condition
      #   describe '#activate' do
      #     context 'when user does NOT exist' do
      #       it { expect { activate }.to raise_error(NotFound) }
      #     end
      #
      #     context 'when user exists' do
      #       it { expect(activate).to be_truthy }
      #     end
      #   end
      #
      # @example Good - happy path first
      #   # good - happy path comes first
      #   describe '#subscribe' do
      #     context 'with valid card' do
      #       it { expect(subscribe).to be_success }
      #     end
      #
      #     context 'but payment fails' do
      #       it { expect(subscribe).to be_failure }
      #     end
      #   end
      #
      #   # good - positive case before negative
      #   describe '#send_notification' do
      #     context 'when user has email' do
      #       it { expect(send_notification).to be_sent }
      #     end
      #
      #     context 'without email' do
      #       it { expect(send_notification).to be_skipped }
      #     end
      #   end
      #
      # @example Edge case - it-blocks represent happy path
      #   # good - examples before first context represent happy path
      #   describe '#add_child' do
      #     it 'adds child to children collection' do
      #       expect { add_child(child) }.to change(parent.children, :count).by(1)
      #     end
      #
      #     context 'but child is already in collection' do
      #       it { expect { add_child(child) }.not_to change(parent.children, :count) }
      #     end
      #   end
      #
      #   # good - multiple it-blocks as happy path
      #   describe '#calculate' do
      #     it { expect(calculate).to be_a(Numeric) }
      #     it { expect(calculate).to be_positive }
      #
      #     context 'with invalid input' do
      #       it { expect { calculate }.to raise_error }
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
            (send nil? :context (str $_description) ...)
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

          # If there are any examples (it/specify) before the first context,
          # this is a happy path, so no offense
          return if has_examples_before_first_context?(node, contexts.first)

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

        def has_examples_before_first_context?(node, first_context)
          body = node.body
          return false unless body

          children = body.begin_type? ? body.children : [body]

          children.each do |child|
            # Stop when we reach the first context
            break if child == first_context

            # Check if this is an example (it/specify)
            return true if example?(child)
          end

          false
        end

        def example?(node)
          return false unless node.block_type?

          send_node = node.send_node
          send_node.method?(:it) || send_node.method?(:specify)
        end

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

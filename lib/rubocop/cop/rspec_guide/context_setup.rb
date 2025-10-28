# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecGuide
      # Checks that context blocks have setup (let/before) to distinguish
      # them from the parent context.
      #
      # Note: subject should be defined at describe level, not in contexts,
      # as it describes the object under test, not context-specific state.
      # Use RSpec/LeadingSubject cop to ensure subject is defined first.
      #
      # @example
      #   # bad
      #   context 'when user is premium' do
      #     it 'has access' do
      #       expect(user).to have_access
      #     end
      #   end
      #
      #   # good
      #   context 'when user is premium' do
      #     let(:user) { create(:user, :premium) }
      #
      #     it 'has access' do
      #       expect(user).to have_access
      #     end
      #   end
      #
      #   # good
      #   context 'when user is premium' do
      #     before { user.upgrade_to_premium! }
      #
      #     it 'has access' do
      #       expect(user).to have_access
      #     end
      #   end
      #
      class ContextSetup < Base
        MSG = "Context should have setup (let/let!/let_it_be/let_it_be!/before) to distinguish it from parent context"

        # @!method context_block?(node)
        def_node_matcher :context_block?, <<~PATTERN
          (block
            (send nil? :context ...)
            ...)
        PATTERN

        # @!method let_declaration?(node)
        def_node_matcher :let_declaration?, <<~PATTERN
          (block (send nil? {:let :let! :let_it_be :let_it_be!} ...) ...)
        PATTERN

        # @!method before_hook?(node)
        def_node_matcher :before_hook?, <<~PATTERN
          (block (send nil? :before ...) ...)
        PATTERN

        def on_block(node)
          return unless context_block?(node)

          # Check if context has at least one setup node (let or before)
          # Note: subject is NOT counted as context setup because it describes
          # the object under test, not context-specific state
          has_setup = has_context_setup?(node)

          add_offense(node) unless has_setup
        end

        private

        def has_context_setup?(context_node)
          # Look for let/before blocks directly in this context
          context_node.each_descendant(:block) do |block_node|
            # Only check immediate children (not nested contexts)
            is_immediate_child = block_node.parent == context_node ||
              (block_node.parent.begin_type? && block_node.parent.parent == context_node)
            next unless is_immediate_child

            return true if let_declaration?(block_node) || before_hook?(block_node)
          end

          false
        end
      end
    end
  end
end

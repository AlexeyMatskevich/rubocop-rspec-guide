# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecGuide
      # Checks that context blocks have setup (let/before) to distinguish
      # them from the parent context.
      #
      # Contexts exist to test different scenarios or states. Without explicit setup,
      # the context doesn't actually change anything from its parent, making the
      # context boundary meaningless and confusing.
      #
      # Valid setup methods: let, let!, let_it_be, let_it_be!, before
      #
      # Note: subject should be defined at describe level, not in contexts,
      # as it describes the object under test, not context-specific state.
      # Use RSpec/LeadingSubject cop to ensure subject is defined first.
      #
      # @safety
      #   This cop is safe to run automatically. It only checks for presence
      #   of setup, not for semantic correctness.
      #
      # @example Bad - no setup
      #   # bad - context has no setup, so what's different?
      #   context 'when user is premium' do
      #     it { expect(user).to have_access }
      #   end
      #
      #   # bad - subject in context (should be in describe)
      #   context 'with custom config' do
      #     subject { Calculator.new(config) }  # Wrong place!
      #     it { is_expected.to be_valid }
      #   end
      #
      # @example Good - using let
      #   # good - let defines context-specific state
      #   context 'when user is premium' do
      #     let(:user) { create(:user, :premium) }
      #     it { expect(user).to have_access }
      #   end
      #
      #   # good - let! for immediate evaluation
      #   context 'with existing records' do
      #     let!(:records) { create_list(:record, 3) }
      #     it { expect(Record.count).to eq(3) }
      #   end
      #
      # @example Good - using let_it_be (test-prof/rspec-rails)
      #   # good - let_it_be for performance (created once per context)
      #   context 'with many users' do
      #     let_it_be(:users) { create_list(:user, 100) }
      #     it { expect(users.size).to eq(100) }
      #   end
      #
      #   # good - let_it_be! for immediate evaluation
      #   context 'with frozen time' do
      #     let_it_be!(:timestamp) { Time.current }
      #     it { expect(timestamp).to be_frozen }
      #   end
      #
      # @example Good - using before
      #   # good - before modifies existing state
      #   context 'when user is upgraded' do
      #     before { user.upgrade_to_premium! }
      #     it { expect(user).to be_premium }
      #   end
      #
      #   # good - before with multiple setup steps
      #   context 'with configured environment' do
      #     before do
      #       allow(ENV).to receive(:[]).with('API_KEY').and_return('test-key')
      #       allow(ENV).to receive(:[]).with('API_URL').and_return('http://test')
      #     end
      #     it { expect(api_client).to be_configured }
      #   end
      #
      # @example Subject placement
      #   # bad - subject in context
      #   describe Calculator do
      #     context 'with custom config' do
      #       subject { Calculator.new(custom_config) }  # Wrong!
      #       it { is_expected.to be_valid }
      #     end
      #   end
      #
      #   # good - subject in describe, config in context
      #   describe Calculator do
      #     subject { Calculator.new(config) }
      #
      #     context 'with custom config' do
      #       let(:config) { CustomConfig.new }  # Right!
      #       it { is_expected.to be_valid }
      #     end
      #   end
      #
      class ContextSetup < RuboCop::Cop::RSpec::Base
        MSG = "Context should have setup (let/let!/let_it_be/let_it_be!/before) to distinguish it from parent context"

        # Using rubocop-rspec API: let?(node) and hook?(node) from Base
        # Custom matcher for context-only:

        # @!method context_only?(node)
        def_node_matcher :context_only?, <<~PATTERN
          (block (send nil? :context ...) ...)
        PATTERN

        def on_block(node)
          # Fast pre-check: only process context blocks
          return unless node.method?(:context)
          return unless context_only?(node)

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

            # Use rubocop-rspec API matchers
            return true if let?(block_node) || (hook?(block_node) && block_node.method?(:before))
          end

          false
        end
      end
    end
  end
end

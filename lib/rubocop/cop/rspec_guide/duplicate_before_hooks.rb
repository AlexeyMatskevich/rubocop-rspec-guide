# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecGuide
      # Detects duplicate before hooks with identical code across sibling contexts.
      #
      # When the same before hook appears in multiple sibling contexts,
      # it indicates one of two problems:
      # 1. ERROR: Duplicate in ALL contexts → must extract to parent
      # 2. WARNING: Duplicate in SOME contexts → suggests poor test hierarchy
      #
      # @safety
      #   This cop is safe to run automatically. It compares hook bodies for
      #   exact matches, not semantic equivalence.
      #
      # @example ERROR - duplicate in ALL contexts
      #   # bad - before hook duplicated in all 2 contexts
      #   describe 'Controller' do
      #     context 'as admin' do
      #       before { sign_in(user) }
      #       it { expect(response).to be_successful }
      #     end
      #
      #     context 'as guest' do
      #       before { sign_in(user) }  # ERROR: in all contexts!
      #       it { expect(response).to be_forbidden }
      #     end
      #   end
      #
      #   # good - extracted to parent
      #   describe 'Controller' do
      #     before { sign_in(user) }  # Moved to parent
      #
      #     context 'as admin' do
      #       it { expect(response).to be_successful }
      #     end
      #
      #     context 'as guest' do
      #       it { expect(response).to be_forbidden }
      #     end
      #   end
      #
      # @example WARNING - duplicate in SOME contexts
      #   # bad - before hook duplicated in 2/3 contexts (code smell)
      #   describe 'API' do
      #     context 'scenario A' do
      #       before { setup_api }
      #       it { expect(response).to be_ok }
      #     end
      #
      #     context 'scenario B' do
      #       before { setup_api }  # WARNING: duplicated in 2/3
      #       it { expect(response).to be_ok }
      #     end
      #
      #     context 'scenario C' do
      #       before { setup_different_api }  # Different setup
      #       it { expect(response).to be_ok }
      #     end
      #   end
      #
      #   # good - refactor hierarchy
      #   describe 'API' do
      #     context 'with standard setup' do
      #       before { setup_api }
      #
      #       context 'scenario A' do
      #         it { expect(response).to be_ok }
      #       end
      #
      #       context 'scenario B' do
      #         it { expect(response).to be_ok }
      #       end
      #     end
      #
      #     context 'with different setup' do
      #       before { setup_different_api }
      #
      #       context 'scenario C' do
      #         it { expect(response).to be_ok }
      #       end
      #     end
      #   end
      #
      # @example Configuration
      #   # To disable warnings for partial duplicates:
      #   RSpecGuide/DuplicateBeforeHooks:
      #     WarnOnPartialDuplicates: false  # Only report full duplicates
      #
      # @example Edge case - different hooks
      #   # good - different before hooks (no duplicate)
      #   describe 'Service' do
      #     context 'with user A' do
      #       before { sign_in(user_a) }
      #       it { expect(service.call).to be_success }
      #     end
      #
      #     context 'with user B' do
      #       before { sign_in(user_b) }  # Different, OK
      #       it { expect(service.call).to be_success }
      #     end
      #   end
      #
      class DuplicateBeforeHooks < RuboCop::Cop::RSpec::Base
        MSG_ERROR = "Duplicate `before` hook in ALL sibling contexts. " \
                    "Extract to parent context."
        MSG_WARNING = "Before hook duplicated in %<count>d/%<total>d sibling contexts. " \
                      "Consider refactoring test hierarchy - this suggests poor organization."

        # Using rubocop-rspec API: example_group?(node) and hook?(node) from Base
        # Custom matchers:

        # @!method context_only?(node)
        def_node_matcher :context_only?, <<~PATTERN
          (block (send nil? :context ...) ...)
        PATTERN

        # @!method before_hook_with_body?(node)
        def_node_matcher :before_hook_with_body?, <<~PATTERN
          (block
            (send nil? :before ...)
            (args)
            $_body)
        PATTERN

        def on_block(node)
          # Fast pre-check: only process describe/context blocks
          return unless node.method?(:describe) || node.method?(:context)
          return unless example_group?(node)

          # Collect all sibling contexts
          sibling_contexts = collect_sibling_contexts(node)
          return if sibling_contexts.size < 2

          # Collect before hooks from each context
          befores_by_context = sibling_contexts.map do |ctx|
            collect_before_hooks(ctx)
          end

          # Find duplicates
          find_duplicate_befores(befores_by_context)
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
            body.children.select { |child| child.block_type? && context_only?(child) }
          elsif body.block_type? && context_only?(body)
            # Single context child
            [body]
          else
            []
          end
        end

        def collect_before_hooks(context_node)
          befores = []

          # The context block has a body that may contain before hooks
          # We need to search within the body for before blocks
          context_node.each_descendant(:block) do |block_node|
            # Only check direct children of the context (not nested in sub-contexts)
            is_immediate_child = block_node.parent == context_node ||
              (block_node.parent.begin_type? && block_node.parent.parent == context_node)
            next unless is_immediate_child

            before_hook_with_body?(block_node) do |body|
              befores << {body_source: normalize_source(body.source), node: block_node}
            end
          end

          befores
        end

        def find_duplicate_befores(befores_by_context)
          # Get all unique before hook sources
          all_befores = befores_by_context.flatten
          unique_sources = all_befores.map { |b| b[:body_source] }.uniq
          total_contexts = befores_by_context.size

          unique_sources.each do |source|
            # Count how many contexts have this before hook
            contexts_with_this_before = befores_by_context.count do |context_befores|
              context_befores.any? { |b| b[:body_source] == source }
            end

            # Skip if only in one context
            next if contexts_with_this_before <= 1

            # ERROR: If this before hook is in ALL sibling contexts
            if contexts_with_this_before == total_contexts
              all_befores.each do |before_info|
                next unless before_info[:body_source] == source

                add_offense(before_info[:node], message: MSG_ERROR)
              end
            # WARNING: If duplicated in multiple (but not all) contexts
            elsif cop_config.fetch("WarnOnPartialDuplicates", true) && contexts_with_this_before >= 2
              all_befores.each do |before_info|
                next unless before_info[:body_source] == source

                add_offense(
                  before_info[:node],
                  message: format(MSG_WARNING, count: contexts_with_this_before, total: total_contexts),
                  severity: :warning
                )
              end
            end
          end
        end

        def normalize_source(source)
          # Normalize code for comparison:
          # - Remove extra whitespace
          # - Remove line breaks at start/end
          source.strip.gsub(/\s+/, " ")
        end
      end
    end
  end
end

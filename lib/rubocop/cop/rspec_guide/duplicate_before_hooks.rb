# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecGuide
      # Detects duplicate before hooks with identical code across all sibling contexts.
      # These should be extracted to the parent context.
      #
      # @example
      #   # bad
      #   describe 'Controller' do
      #     context 'as admin' do
      #       before { sign_in(user) }
      #       it { expect(response).to be_successful }
      #     end
      #
      #     context 'as guest' do
      #       before { sign_in(user) }  # Duplicate!
      #       it { expect(response).to be_forbidden }
      #     end
      #   end
      #
      #   # good
      #   describe 'Controller' do
      #     before { sign_in(user) }  # Extracted to parent
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
      class DuplicateBeforeHooks < Base
        MSG_ERROR = "Duplicate `before` hook in ALL sibling contexts. " \
                    "Extract to parent context."
        MSG_WARNING = "Before hook duplicated in %<count>d/%<total>d sibling contexts. " \
                      "Consider refactoring test hierarchy - this suggests poor organization."

        # @!method context_block?(node)
        def_node_matcher :context_block?, <<~PATTERN
          (block (send nil? :context ...) ...)
        PATTERN

        # @!method before_hook?(node)
        def_node_matcher :before_hook?, <<~PATTERN
          (block
            (send nil? :before ...)
            (args)
            $_body)
        PATTERN

        # @!method example_group?(node)
        def_node_matcher :example_group?, <<~PATTERN
          (block
            (send nil? {:describe :context} ...)
            ...)
        PATTERN

        def on_block(node)
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
            body.children.select { |child| child.block_type? && context_block?(child) }
          elsif body.block_type? && context_block?(body)
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

            before_hook?(block_node) do |body|
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

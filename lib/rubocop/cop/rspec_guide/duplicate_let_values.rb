# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecGuide
      # Detects duplicate let declarations with identical values across sibling contexts.
      #
      # When the same let with the same value appears in multiple sibling contexts,
      # it indicates one of two problems:
      # 1. ERROR: Duplicate in ALL contexts → must extract to parent
      # 2. WARNING: Duplicate in SOME contexts → suggests poor test hierarchy
      #
      # @safety
      #   This cop is safe to run automatically. It only detects duplicates,
      #   not semantic issues.
      #
      # @example ERROR - duplicate in ALL contexts
      #   # bad - let(:currency) duplicated in all 2 contexts
      #   describe 'Calculator' do
      #     context 'with addition' do
      #       let(:currency) { :usd }
      #       it { expect(result).to eq(10) }
      #     end
      #
      #     context 'with subtraction' do
      #       let(:currency) { :usd }  # ERROR: in all contexts!
      #       it { expect(result).to eq(5) }
      #     end
      #   end
      #
      #   # good - extracted to parent
      #   describe 'Calculator' do
      #     let(:currency) { :usd }  # Moved to parent
      #
      #     context 'with addition' do
      #       it { expect(result).to eq(10) }
      #     end
      #
      #     context 'with subtraction' do
      #       it { expect(result).to eq(5) }
      #     end
      #   end
      #
      # @example WARNING - duplicate in SOME contexts
      #   # bad - let(:mode) duplicated in 2/3 contexts (code smell)
      #   describe 'Processor' do
      #     context 'scenario A' do
      #       let(:mode) { :standard }
      #       it { expect(result).to eq('A') }
      #     end
      #
      #     context 'scenario B' do
      #       let(:mode) { :standard }  # WARNING: duplicated in 2/3
      #       it { expect(result).to eq('B') }
      #     end
      #
      #     context 'scenario C' do
      #       let(:mode) { :advanced }  # Different value
      #       it { expect(result).to eq('C') }
      #     end
      #   end
      #
      #   # good - refactor hierarchy
      #   describe 'Processor' do
      #     context 'with standard mode' do
      #       let(:mode) { :standard }
      #
      #       context 'scenario A' do
      #         it { expect(result).to eq('A') }
      #       end
      #
      #       context 'scenario B' do
      #         it { expect(result).to eq('B') }
      #       end
      #     end
      #
      #     context 'with advanced mode' do
      #       let(:mode) { :advanced }
      #
      #       context 'scenario C' do
      #         it { expect(result).to eq('C') }
      #       end
      #     end
      #   end
      #
      # @example Configuration
      #   # To disable warnings for partial duplicates:
      #   RSpecGuide/DuplicateLetValues:
      #     WarnOnPartialDuplicates: false  # Only report full duplicates
      #
      # @example Edge case - different values
      #   # good - same let name but different values (no duplicate)
      #   describe 'Converter' do
      #     context 'to USD' do
      #       let(:currency) { :usd }
      #       it { expect(convert).to eq(100) }
      #     end
      #
      #     context 'to EUR' do
      #       let(:currency) { :eur }  # Different value, OK
      #       it { expect(convert).to eq(85) }
      #     end
      #   end
      #
      class DuplicateLetValues < RuboCop::Cop::RSpec::Base
        MSG_ERROR = "Duplicate `let(:%<name>s)` with same value `%<value>s` " \
                    "in ALL sibling contexts. Extract to parent context."
        MSG_WARNING = "Let `:%<name>s` with value `%<value>s` duplicated in %<count>d/%<total>d contexts. " \
                      "Consider refactoring test hierarchy - this suggests poor organization."

        # Using rubocop-rspec API: example_group?(node) from Base
        # Custom matchers:

        # @!method context_only?(node)
        def_node_matcher :context_only?, <<~PATTERN
          (block (send nil? :context ...) ...)
        PATTERN

        # @!method let_with_name_and_value?(node)
        def_node_matcher :let_with_name_and_value?, <<~PATTERN
          (block
            (send nil? {:let :let!} (sym $_name))
            (args)
            $_value)
        PATTERN

        def on_block(node)
          # Fast pre-check: only process describe/context blocks
          return unless node.method?(:describe) || node.method?(:context)
          return unless example_group?(node)

          # Collect all sibling contexts
          sibling_contexts = collect_sibling_contexts(node)
          return if sibling_contexts.size < 2

          # Collect let declarations from each context
          lets_by_context = sibling_contexts.map do |ctx|
            collect_lets_in_context(ctx)
          end

          # Find duplicates
          find_duplicate_lets(lets_by_context)
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

        def collect_lets_in_context(context_node)
          lets = {}

          # Search within the context body for let declarations
          context_node.each_descendant(:block) do |block_node|
            # Only check direct children of the context (not nested in sub-contexts)
            is_immediate_child = block_node.parent == context_node ||
              (block_node.parent.begin_type? && block_node.parent.parent == context_node)
            next unless is_immediate_child

            let_with_name_and_value?(block_node) do |name, value|
              # Only check simple values that can be compared by source
              if simple_value?(value)
                lets[name] = {value: value.source, node: block_node}
              end
            end
          end

          lets
        end

        def find_duplicate_lets(lets_by_context)
          # Get all let names across contexts
          all_let_names = lets_by_context.flat_map(&:keys).uniq
          total_contexts = lets_by_context.size

          all_let_names.each do |let_name|
            # Find contexts that have this let
            contexts_with_let = lets_by_context.select { |lets| lets.key?(let_name) }

            # Skip if only in one context
            next if contexts_with_let.size <= 1

            # Collect all values
            values = contexts_with_let.map { |lets| lets[let_name][:value] }

            # Skip if values differ
            next unless values.uniq.size == 1

            value = values.first

            # ERROR: If let with same value is in ALL contexts
            if contexts_with_let.size == total_contexts
              contexts_with_let.each do |lets|
                add_offense(
                  lets[let_name][:node],
                  message: format(MSG_ERROR, name: let_name, value: value)
                )
              end
            # WARNING: If duplicated in multiple (but not all) contexts
            elsif cop_config.fetch("WarnOnPartialDuplicates", true) && contexts_with_let.size >= 2
              contexts_with_let.each do |lets|
                add_offense(
                  lets[let_name][:node],
                  message: format(MSG_WARNING, name: let_name, value: value,
                    count: contexts_with_let.size, total: total_contexts),
                  severity: :warning
                )
              end
            end
          end
        end

        def simple_value?(node)
          return false if node.nil?

          # Values we can safely compare by source
          return true if node.sym_type? || node.str_type? || node.int_type? || node.float_type?
          return true if node.true_type? || node.false_type? || node.nil_type?

          # Handle hash pair nodes (key-value pairs inside hashes)
          if node.pair_type?
            return simple_value?(node.key) && simple_value?(node.value)
          end

          if node.hash_type?
            # Hash children are pair nodes
            return node.children.all? { |child| simple_value?(child) }
          end

          if node.array_type?
            # Array children can be any simple values
            return node.children.all? { |child| simple_value?(child) }
          end

          # Method calls like create(:user), build(:post), etc.
          # We can compare these by source code
          return true if node.send_type?

          # Blocks like { Time.now } - compare by source
          return true if node.block_type?

          false
        end
      end
    end
  end
end

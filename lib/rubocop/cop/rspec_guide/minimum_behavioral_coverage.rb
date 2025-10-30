# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecGuide
      # Checks that describe blocks test at least 2 behavioral variations.
      #
      # Testing only a single scenario (happy path OR edge case) provides
      # insufficient coverage. Tests should verify both expected behavior
      # and edge case handling to ensure comprehensive validation.
      #
      # This can be achieved in two ways:
      # 1. Use 2+ sibling context blocks (happy path + edge cases)
      # 2. Combine it-blocks (default behavior) with context-blocks (edge cases)
      #
      # @safety
      #   This cop is safe to run automatically. For simple methods like getters
      #   with no edge cases, use `# rubocop:disable RSpecGuide/MinimumBehavioralCoverage`
      #
      # @example Traditional approach - 2+ sibling contexts
      #   # bad - only one scenario (no edge case testing)
      #   describe '#calculate' do
      #     context 'with valid data' do
      #       it { expect(result).to eq(100) }
      #     end
      #   end
      #
      #   # good - multiple scenarios (happy path + edge cases)
      #   describe '#calculate' do
      #     context 'with valid data' do
      #       it { expect(result).to eq(100) }
      #     end
      #
      #     context 'with invalid data' do
      #       it { expect { result }.to raise_error(ValidationError) }
      #     end
      #   end
      #
      #   # good - more comprehensive coverage
      #   describe '#calculate' do
      #     context 'with positive numbers' do
      #       it { expect(result).to eq(100) }
      #     end
      #
      #     context 'with zero' do
      #       it { expect(result).to eq(0) }
      #     end
      #
      #     context 'with negative numbers' do
      #       it { expect { result }.to raise_error(ArgumentError) }
      #     end
      #   end
      #
      # @example New pattern - it-blocks + context-blocks
      #   # bad - only default behavior, no edge cases
      #   describe '#calculate' do
      #     it 'calculates sum' { expect(result).to eq(100) }
      #   end
      #
      #   # good - default behavior + edge case
      #   describe '#calculate' do
      #     it 'calculates sum with defaults' { expect(result).to eq(100) }
      #
      #     context 'with invalid input' do
      #       it { expect { result }.to raise_error(ValidationError) }
      #     end
      #   end
      #
      #   # good - multiple it-blocks for defaults, context for edge case
      #   describe '#calculate' do
      #     it 'returns numeric result' { expect(result).to be_a(Numeric) }
      #     it 'is positive' { expect(result).to be > 0 }
      #
      #     context 'with special conditions' do
      #       it { expect(result).to eq(0) }
      #     end
      #   end
      #
      # @example Edge case - setup before tests (allowed)
      #   # good - setup + it-blocks + contexts
      #   describe '#calculate' do
      #     let(:calculator) { Calculator.new }
      #     before { calculator.configure }
      #
      #     it 'works with defaults' { expect(result).to eq(100) }
      #
      #     context 'with custom config' do
      #       it { expect(result).to eq(200) }
      #     end
      #   end
      #
      # @example When to disable this cop
      #   # Simple getter with no edge cases - disable is acceptable
      #   describe '#name' do # rubocop:disable RSpecGuide/MinimumBehavioralCoverage
      #     it { expect(subject.name).to eq('test') }
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

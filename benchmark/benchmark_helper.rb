# frozen_string_literal: true

require "benchmark/ips"
require "rubocop"
require_relative "../lib/rubocop-rspec-guide"

# Helper module for running benchmarks on cops
module BenchmarkHelper
  # Run a cop against the given source code
  #
  # @param cop_class [Class] The cop class to benchmark
  # @param source [String] The source code to analyze
  # @return [Array<RuboCop::Cop::Offense>] The offenses found
  def self.run_cop(cop_class, source)
    cop = cop_class.new
    processed_source = parse_source(source)
    commissioner = RuboCop::Cop::Commissioner.new([cop])
    commissioner.investigate(processed_source)
  end

  # Parse source code into a ProcessedSource
  #
  # @param source [String] The source code to parse
  # @return [RuboCop::ProcessedSource] The parsed source
  def self.parse_source(source)
    RuboCop::ProcessedSource.new(
      source,
      ruby_version,
      nil
    )
  end

  # Get the current Ruby version
  #
  # @return [Float] The Ruby version
  def self.ruby_version
    RUBY_VERSION.to_f
  end

  # Generate sample RSpec code with the given number of examples
  #
  # @param examples_count [Integer] Number of examples to generate
  # @return [String] Generated RSpec code
  def self.generate_rspec_code(examples_count: 10)
    examples = (1..examples_count).map do |i|
      <<~RUBY
        it "does something #{i}" do
          expect(subject.call).to eq(#{i})
        end
      RUBY
    end

    <<~RUBY
      RSpec.describe MyClass do
        subject { MyClass.new }

        #{examples.join("\n")}
      end
    RUBY
  end

  # Generate sample RSpec code with contexts
  #
  # @param contexts_count [Integer] Number of contexts to generate
  # @param examples_per_context [Integer] Number of examples per context
  # @return [String] Generated RSpec code
  def self.generate_context_code(contexts_count: 5, examples_per_context: 3)
    contexts = (1..contexts_count).map do |i|
      examples = (1..examples_per_context).map do |j|
        <<~RUBY
          it "does something #{j}" do
            expect(result).to eq(#{j})
          end
        RUBY
      end

      <<~RUBY
        context "when condition #{i}" do
          let(:value) { #{i} }

          #{examples.join("\n")}
        end
      RUBY
    end

    <<~RUBY
      RSpec.describe MyClass do
        #{contexts.join("\n")}
      end
    RUBY
  end
end

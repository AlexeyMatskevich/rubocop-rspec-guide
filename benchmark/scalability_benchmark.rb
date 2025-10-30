#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "benchmark_helper"

# Benchmark cops with different file sizes
puts "=" * 80
puts "RuboCop RSpec Guide - Scalability Benchmark"
puts "Testing how cops perform with different file sizes"
puts "=" * 80
puts ""

# Configure benchmark timing based on environment
if ENV["FULL_BENCHMARK"]
  WARMUP_TIME = 2
  MEASUREMENT_TIME = 5
  puts "Mode: FULL (accurate measurements)"
else
  WARMUP_TIME = 1
  MEASUREMENT_TIME = 2
  puts "Mode: QUICK (fast feedback)"
end
puts ""

# Test with increasing number of contexts
Benchmark.ips do |x|
  x.config(time: MEASUREMENT_TIME, warmup: WARMUP_TIME)

  [5, 10, 20, 50].each do |contexts_count|
    source = BenchmarkHelper.generate_context_code(
      contexts_count: contexts_count,
      examples_per_context: 3
    )

    x.report("MinimumBehavioralCoverage - #{contexts_count} contexts") do
      BenchmarkHelper.run_cop(
        RuboCop::Cop::RSpecGuide::MinimumBehavioralCoverage,
        source
      )
    end
  end

  x.compare!
end

puts "\n"

# Test with increasing number of examples
Benchmark.ips do |x|
  x.config(time: MEASUREMENT_TIME, warmup: WARMUP_TIME)

  [10, 25, 50, 100].each do |examples_count|
    source = BenchmarkHelper.generate_rspec_code(examples_count: examples_count)

    x.report("ContextSetup - #{examples_count} examples") do
      BenchmarkHelper.run_cop(
        RuboCop::Cop::RSpecGuide::ContextSetup,
        source
      )
    end
  end

  x.compare!
end

puts "\n"

# Test DuplicateLetValues with nested contexts
Benchmark.ips do |x|
  x.config(time: MEASUREMENT_TIME, warmup: WARMUP_TIME)

  [3, 5, 10, 15].each do |nesting_level|
    contexts = (1..nesting_level).map do |i|
      indent = "  " * i
      <<~RUBY
        #{indent}context "level #{i}" do
        #{indent}  let(:value) { #{i} }
        #{indent}
        #{indent}  it "works" do
        #{indent}    expect(value).to eq(#{i})
        #{indent}  end
      RUBY
    end

    source = <<~RUBY
      RSpec.describe MyClass do
      #{contexts.join("\n")}
      #{"  end\n" * nesting_level}
      end
    RUBY

    x.report("DuplicateLetValues - #{nesting_level} nesting levels") do
      BenchmarkHelper.run_cop(
        RuboCop::Cop::RSpecGuide::DuplicateLetValues,
        source
      )
    end
  end

  x.compare!
end

puts "\n"

# Test InvariantExamples with many duplicates
Benchmark.ips do |x|
  x.config(time: MEASUREMENT_TIME, warmup: WARMUP_TIME)

  [2, 5, 10, 15].each do |duplicates_count|
    contexts = (1..duplicates_count).map do |i|
      <<~RUBY
        context "scenario #{i}" do
          it "validates input" do
            expect(subject).to respond_to(:valid?)
          end

          it "has specific behavior" do
            expect(subject.call(#{i})).to eq(#{i})
          end
        end
      RUBY
    end

    source = <<~RUBY
      RSpec.describe MyClass do
        #{contexts.join("\n")}
      end
    RUBY

    x.report("InvariantExamples - #{duplicates_count} duplicates") do
      BenchmarkHelper.run_cop(
        RuboCop::Cop::RSpecGuide::InvariantExamples,
        source
      )
    end
  end

  x.compare!
end

puts "\n"

# Memory usage test
require "objspace"

puts "=" * 80
puts "Memory Usage Analysis"
puts "=" * 80
puts ""

large_source = BenchmarkHelper.generate_context_code(
  contexts_count: 50,
  examples_per_context: 10
)

cops = [
  RuboCop::Cop::RSpecGuide::MinimumBehavioralCoverage,
  RuboCop::Cop::RSpecGuide::HappyPathFirst,
  RuboCop::Cop::RSpecGuide::ContextSetup,
  RuboCop::Cop::RSpecGuide::DuplicateLetValues,
  RuboCop::Cop::RSpecGuide::DuplicateBeforeHooks,
  RuboCop::Cop::RSpecGuide::InvariantExamples,
  RuboCop::Cop::FactoryBotGuide::DynamicAttributeEvaluation
]

cops.each do |cop_class|
  GC.start
  before = ObjectSpace.memsize_of_all

  BenchmarkHelper.run_cop(cop_class, large_source)

  after = ObjectSpace.memsize_of_all
  memory_used = (after - before) / 1024.0 / 1024.0

  puts "#{cop_class.cop_name}: #{"%.2f" % memory_used} MB"
end

puts "\n"
puts "=" * 80
puts "Scalability benchmark completed!"
puts "=" * 80

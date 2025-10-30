#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "benchmark_helper"

# Benchmark all RSpecGuide cops
puts "=" * 80
puts "RuboCop RSpec Guide - Cops Performance Benchmark"
puts "=" * 80
puts ""

# Configure benchmark timing based on environment
#   FULL_BENCHMARK=1 - Full mode: longer warmup/measurement for accuracy (~5 minutes)
#   Default - Quick mode: shorter warmup/measurement for fast feedback (~1 minute)
if ENV["FULL_BENCHMARK"]
  WARMUP_TIME = 2
  MEASUREMENT_TIME = 5
  puts "Mode: FULL (accurate measurements, ~5 minutes)"
else
  WARMUP_TIME = 1
  MEASUREMENT_TIME = 2
  puts "Mode: QUICK (fast feedback, ~1 minute)"
  puts "Tip: Use FULL_BENCHMARK=1 for more accurate measurements"
end
puts ""

# Benchmark MinimumBehavioralCoverage
Benchmark.ips do |x|
  x.config(time: MEASUREMENT_TIME, warmup: WARMUP_TIME)

  source_with_violation = <<~RUBY
    RSpec.describe User do
      context "when user is valid" do
        it "saves successfully" do
          expect(user.save).to be true
        end
      end
    end
  RUBY

  source_without_violation = <<~RUBY
    RSpec.describe User do
      context "when user is valid" do
        it "saves successfully" do
          expect(user.save).to be true
        end
      end

      context "when user is invalid" do
        it "does not save" do
          expect(user.save).to be false
        end
      end
    end
  RUBY

  x.report("MinimumBehavioralCoverage (with violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::RSpecGuide::MinimumBehavioralCoverage,
      source_with_violation
    )
  end

  x.report("MinimumBehavioralCoverage (without violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::RSpecGuide::MinimumBehavioralCoverage,
      source_without_violation
    )
  end

  x.compare!
end

puts "\n"

# Benchmark HappyPathFirst
Benchmark.ips do |x|
  x.config(time: MEASUREMENT_TIME, warmup: WARMUP_TIME)

  source_with_violation = <<~RUBY
    RSpec.describe User do
      context "when email is invalid" do
        it "returns error" do
          expect(user.valid?).to be false
        end
      end

      context "when email is valid" do
        it "is valid" do
          expect(user.valid?).to be true
        end
      end
    end
  RUBY

  source_without_violation = <<~RUBY
    RSpec.describe User do
      context "when email is valid" do
        it "is valid" do
          expect(user.valid?).to be true
        end
      end

      context "when email is invalid" do
        it "returns error" do
          expect(user.valid?).to be false
        end
      end
    end
  RUBY

  x.report("HappyPathFirst (with violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::RSpecGuide::HappyPathFirst,
      source_with_violation
    )
  end

  x.report("HappyPathFirst (without violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::RSpecGuide::HappyPathFirst,
      source_without_violation
    )
  end

  x.compare!
end

puts "\n"

# Benchmark ContextSetup
Benchmark.ips do |x|
  x.config(time: MEASUREMENT_TIME, warmup: WARMUP_TIME)

  source_with_violation = <<~RUBY
    RSpec.describe User do
      context "when user is admin" do
        it "has admin privileges" do
          user = create(:user, :admin)
          expect(user.admin?).to be true
        end
      end
    end
  RUBY

  source_without_violation = <<~RUBY
    RSpec.describe User do
      context "when user is admin" do
        let(:user) { create(:user, :admin) }

        it "has admin privileges" do
          expect(user.admin?).to be true
        end
      end
    end
  RUBY

  x.report("ContextSetup (with violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::RSpecGuide::ContextSetup,
      source_with_violation
    )
  end

  x.report("ContextSetup (without violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::RSpecGuide::ContextSetup,
      source_without_violation
    )
  end

  x.compare!
end

puts "\n"

# Benchmark DuplicateLetValues
Benchmark.ips do |x|
  x.config(time: MEASUREMENT_TIME, warmup: WARMUP_TIME)

  source_with_violation = <<~RUBY
    RSpec.describe Calculator do
      context "with positive numbers" do
        let(:value) { 42 }

        it "works" do
          expect(value).to eq(42)
        end
      end

      context "with negative numbers" do
        let(:value) { 42 }

        it "works differently" do
          expect(value).to eq(42)
        end
      end
    end
  RUBY

  source_without_violation = <<~RUBY
    RSpec.describe Calculator do
      let(:default_value) { 42 }

      context "with positive numbers" do
        let(:value) { default_value }

        it "works" do
          expect(value).to eq(42)
        end
      end

      context "with negative numbers" do
        let(:value) { -default_value }

        it "works differently" do
          expect(value).to eq(-42)
        end
      end
    end
  RUBY

  x.report("DuplicateLetValues (with violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::RSpecGuide::DuplicateLetValues,
      source_with_violation
    )
  end

  x.report("DuplicateLetValues (without violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::RSpecGuide::DuplicateLetValues,
      source_without_violation
    )
  end

  x.compare!
end

puts "\n"

# Benchmark DuplicateBeforeHooks
Benchmark.ips do |x|
  x.config(time: MEASUREMENT_TIME, warmup: WARMUP_TIME)

  source_with_violation = <<~RUBY
    RSpec.describe Service do
      context "with feature enabled" do
        before do
          setup_database
        end

        it "works" do
          expect(service.call).to be_success
        end
      end

      context "with feature disabled" do
        before do
          setup_database
        end

        it "still works" do
          expect(service.call).to be_success
        end
      end
    end
  RUBY

  source_without_violation = <<~RUBY
    RSpec.describe Service do
      before do
        setup_database
      end

      context "with feature enabled" do
        it "works" do
          expect(service.call).to be_success
        end
      end

      context "with feature disabled" do
        it "still works" do
          expect(service.call).to be_success
        end
      end
    end
  RUBY

  x.report("DuplicateBeforeHooks (with violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::RSpecGuide::DuplicateBeforeHooks,
      source_with_violation
    )
  end

  x.report("DuplicateBeforeHooks (without violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::RSpecGuide::DuplicateBeforeHooks,
      source_without_violation
    )
  end

  x.compare!
end

puts "\n"

# Benchmark InvariantExamples
Benchmark.ips do |x|
  x.config(time: MEASUREMENT_TIME, warmup: WARMUP_TIME)

  source_with_violation = <<~RUBY
    RSpec.describe Calculator do
      context "with integers" do
        it "adds numbers" do
          expect(calculator.add(1, 2)).to eq(3)
        end

        it "returns numeric result" do
          expect(calculator.add(1, 2)).to be_a(Numeric)
        end
      end

      context "with floats" do
        it "adds numbers" do
          expect(calculator.add(1.5, 2.5)).to eq(4.0)
        end

        it "returns numeric result" do
          expect(calculator.add(1.5, 2.5)).to be_a(Numeric)
        end
      end
    end
  RUBY

  source_without_violation = <<~RUBY
    RSpec.describe Calculator do
      shared_examples "returns numeric result" do
        it "returns numeric result" do
          expect(result).to be_a(Numeric)
        end
      end

      context "with integers" do
        let(:result) { calculator.add(1, 2) }

        it "adds numbers" do
          expect(result).to eq(3)
        end

        include_examples "returns numeric result"
      end

      context "with floats" do
        let(:result) { calculator.add(1.5, 2.5) }

        it "adds numbers" do
          expect(result).to eq(4.0)
        end

        include_examples "returns numeric result"
      end
    end
  RUBY

  x.report("InvariantExamples (with violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::RSpecGuide::InvariantExamples,
      source_with_violation
    )
  end

  x.report("InvariantExamples (without violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::RSpecGuide::InvariantExamples,
      source_without_violation
    )
  end

  x.compare!
end

puts "\n"

# Benchmark DynamicAttributeEvaluation
Benchmark.ips do |x|
  x.config(time: MEASUREMENT_TIME, warmup: WARMUP_TIME)

  source_with_violation = <<~RUBY
    FactoryBot.define do
      factory :user do
        created_at { Time.current }
        random_number { rand(1..100) }
      end
    end
  RUBY

  source_without_violation = <<~RUBY
    FactoryBot.define do
      factory :user do
        created_at { -> { Time.current } }
        random_number { -> { rand(1..100) } }
      end
    end
  RUBY

  x.report("DynamicAttributeEvaluation (with violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::FactoryBotGuide::DynamicAttributeEvaluation,
      source_with_violation
    )
  end

  x.report("DynamicAttributeEvaluation (without violation)") do
    BenchmarkHelper.run_cop(
      RuboCop::Cop::FactoryBotGuide::DynamicAttributeEvaluation,
      source_without_violation
    )
  end

  x.compare!
end

puts "\n"
puts "=" * 80
puts "Benchmark completed!"
puts "=" * 80

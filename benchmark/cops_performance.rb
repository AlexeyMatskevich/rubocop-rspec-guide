#!/usr/bin/env ruby
# frozen_string_literal: true

require "benchmark"
require "rubocop"
require_relative "../lib/rubocop-rspec-guide"

# Sample RSpec code for benchmarking
SAMPLE_CODE = <<~RUBY
  describe 'UserService' do
    context 'when user is admin' do
      let(:user) { create(:user, :admin) }
      let(:service) { UserService.new(user) }

      before { setup_admin_permissions }

      it 'has admin access' do
        expect(service.admin?).to be true
      end

      it 'can modify settings' do
        expect(service.can_modify_settings?).to be true
      end
    end

    context 'when user is regular' do
      let(:user) { create(:user) }
      let(:service) { UserService.new(user) }

      before { setup_admin_permissions }

      it 'does not have admin access' do
        expect(service.admin?).to be false
      end

      it 'cannot modify settings' do
        expect(service.can_modify_settings?).to be false
      end
    end
  end
RUBY

puts "=" * 80
puts "RuboCop RSpec Cops Performance Benchmark"
puts "=" * 80
puts "Sample code: #{SAMPLE_CODE.lines.count} lines"
puts "Ruby version: #{RUBY_VERSION}"
puts "RuboCop version: #{RuboCop::Version.version}"
puts "=" * 80
puts

# Parse the code once
source = RuboCop::ProcessedSource.new(SAMPLE_CODE, RUBY_VERSION.to_f)

# Create config
config = RuboCop::Config.new(
  {
    "RSpec" => {
      "Enabled" => true,
      "Language" => {
        "ExampleGroups" => {
          "Regular" => %w[describe context]
        },
        "Examples" => {
          "Regular" => %w[it]
        },
        "Helpers" => %w[let let!],
        "Hooks" => %w[before after],
        "Subjects" => %w[subject]
      }
    }
  }
)

cops = [
  RuboCop::Cop::RSpecGuide::MinimumBehavioralCoverage,
  RuboCop::Cop::RSpecGuide::HappyPathFirst,
  RuboCop::Cop::RSpecGuide::ContextSetup,
  RuboCop::Cop::RSpecGuide::DuplicateLetValues,
  RuboCop::Cop::RSpecGuide::DuplicateBeforeHooks,
  RuboCop::Cop::RSpecGuide::InvariantExamples
]

iterations = 1000

Benchmark.bm(40) do |x|
  cops.each do |cop_class|
    x.report(cop_class.badge.to_s) do
      iterations.times do
        cop = cop_class.new(config)
        commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: false)
        commissioner.investigate(source)
      end
    end
  end

  x.report("All 6 cops together") do
    iterations.times do
      cop_instances = cops.map { |c| c.new(config) }
      commissioner = RuboCop::Cop::Commissioner.new(cop_instances, [], raise_error: false)
      commissioner.investigate(source)
    end
  end
end

puts
puts "=" * 80
puts "Benchmark complete! (#{iterations} iterations per cop)"
puts "=" * 80

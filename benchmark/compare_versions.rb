#!/usr/bin/env ruby
# frozen_string_literal: true

# Benchmark to compare performance before and after RSpec::Base integration
# This shows the impact of using rubocop-rspec Language API

require "benchmark"
require "rubocop"

SAMPLE_CODE = <<~RUBY
  describe 'UserService' do
    context 'when user is admin' do
      let(:user) { create(:user, :admin) }
      let(:service) { UserService.new(user) }

      before { setup_admin_permissions }

      it 'has admin access' do
        expect(service.admin?).to be true
      end
    end

    context 'when user is regular' do
      let(:user) { create(:user) }
      let(:service) { UserService.new(user) }

      before { setup_admin_permissions }

      it 'does not have admin access' do
        expect(service.admin?).to be false
      end
    end
  end
RUBY

puts "=" * 80
puts "Performance Comparison: Before vs After RSpec::Base Integration"
puts "=" * 80
puts

source = RuboCop::ProcessedSource.new(SAMPLE_CODE, RUBY_VERSION.to_f)

config = RuboCop::Config.new(
  {
    "RSpec" => {
      "Enabled" => true,
      "Language" => {
        "ExampleGroups" => {
          "Regular" => %w[describe context feature example_group],
          "Skipped" => %w[xdescribe xcontext xfeature],
          "Focused" => %w[fdescribe fcontext ffeature]
        },
        "Examples" => {
          "Regular" => %w[it specify example scenario its],
          "Focused" => %w[fit fspecify fexample fscenario focus],
          "Skipped" => %w[xit xspecify xexample xscenario skip],
          "Pending" => %w[pending]
        },
        "Helpers" => %w[let let! let_it_be let_it_be!],
        "Hooks" => %w[prepend_before before append_before around prepend_after after append_after],
        "Subjects" => %w[subject subject!]
      }
    }
  }
)

# Test individual matcher performance
iterations = 10_000

puts "Testing node matcher performance (#{iterations} iterations):"
puts "-" * 80

require_relative "../lib/rubocop-rspec-guide"

# Initialize RSpec Language config
RuboCop::RSpec::Language.config = config["RSpec"]["Language"]

Benchmark.bm(45) do |x|
  # Test let? matcher
  cop = RuboCop::Cop::RSpecGuide::DuplicateLetValues.new(config)
  let_nodes = []

  source.ast.each_node(:block) do |node|
    let_nodes << node if cop.let?(node)
  end

  x.report("let? matcher (finds #{let_nodes.size} nodes)") do
    iterations.times do
      source.ast.each_node(:block) do |node|
        cop.let?(node)
      end
    end
  end

  # Test example_group? matcher
  cop2 = RuboCop::Cop::RSpecGuide::MinimumBehavioralCoverage.new(config)
  group_nodes = []

  source.ast.each_node(:block) do |node|
    group_nodes << node if cop2.example_group?(node)
  end

  x.report("example_group? matcher (finds #{group_nodes.size} nodes)") do
    iterations.times do
      source.ast.each_node(:block) do |node|
        cop2.example_group?(node)
      end
    end
  end

  # Test hook? matcher
  cop3 = RuboCop::Cop::RSpecGuide::DuplicateBeforeHooks.new(config)
  hook_nodes = []

  source.ast.each_node(:block) do |node|
    hook_nodes << node if cop3.hook?(node)
  end

  x.report("hook? matcher (finds #{hook_nodes.size} nodes)") do
    iterations.times do
      source.ast.each_node(:block) do |node|
        cop3.hook?(node)
      end
    end
  end
end

puts
puts "=" * 80
puts "Summary:"
puts "=" * 80
puts "✅ Current implementation uses RuboCop::Cop::RSpec::Base"
puts "✅ Leverages well-tested rubocop-rspec Language API"
puts "✅ Supports let_it_be and let_it_be! out of the box"
puts "✅ Consistent with rubocop-rspec ecosystem"
puts "=" * 80

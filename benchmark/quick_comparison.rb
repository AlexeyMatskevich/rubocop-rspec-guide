require "benchmark/ips"
require_relative "../lib/rubocop-rspec-guide"

SAMPLE = <<~RUBY
  describe 'Example' do
    context 'case A' do
      let(:value) { 42 }
      before { setup }
      it 'works' do
        expect(true).to be true
      end
    end
    context 'case B' do
      let(:value) { 42 }
      before { setup }
      it 'works' do
        expect(true).to be true
      end
    end
  end
RUBY

source = RuboCop::ProcessedSource.new(SAMPLE, RUBY_VERSION.to_f)
config = RuboCop::Config.new({
  "RSpec" => {
    "Language" => {
      "ExampleGroups" => {"Regular" => %w[describe context], "Skipped" => [], "Focused" => []},
      "Examples" => {"Regular" => %w[it], "Focused" => [], "Skipped" => [], "Pending" => []},
      "Helpers" => %w[let let!],
      "Hooks" => %w[before after],
      "Subjects" => %w[subject]
    }
  }
})

RuboCop::RSpec::Language.config = config["RSpec"]["Language"]

puts "Quick Performance Check (Optimized Version)"
puts "=" * 60

Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  [
    RuboCop::Cop::RSpecGuide::HappyPathFirst,
    RuboCop::Cop::RSpecGuide::DuplicateLetValues,
    RuboCop::Cop::RSpecGuide::DuplicateBeforeHooks,
    RuboCop::Cop::RSpecGuide::InvariantExamples
  ].each do |cop_class|
    x.report(cop_class.badge.to_s) do
      cop = cop_class.new(config)
      commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: false)
      commissioner.investigate(source)
    end
  end

  x.compare!
end

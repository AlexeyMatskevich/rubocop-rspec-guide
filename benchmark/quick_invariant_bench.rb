require "benchmark/ips"
require_relative "../lib/rubocop-rspec-guide"

SAMPLE = <<~RUBY
  describe 'Validator' do
    context 'with valid data' do
      it 'responds to valid?' do
        expect(subject).to respond_to(:valid?)
      end
    end
    context 'with invalid data' do
      it 'responds to valid?' do
        expect(subject).to respond_to(:valid?)
      end
    end
    context 'with edge case' do
      it 'responds to valid?' do
        expect(subject).to respond_to(:valid?)
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
      "Helpers" => %w[let],
      "Hooks" => %w[before],
      "Subjects" => %w[subject]
    }
  },
  "RSpecGuide/InvariantExamples" => {"MinLeafContexts" => 3}
})

RuboCop::RSpec::Language.config = config["RSpec"]["Language"]

puts "Benchmarking InvariantExamples (optimized with local matcher)"
puts "Expected baseline: ~1504 i/s, Previous (slow): ~854 i/s"
puts ""

Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  x.report("InvariantExamples") do
    cop = RuboCop::Cop::RSpecGuide::InvariantExamples.new(config)
    commissioner = RuboCop::Cop::Commissioner.new([cop], [], raise_error: false)
    commissioner.investigate(source)
  end
end

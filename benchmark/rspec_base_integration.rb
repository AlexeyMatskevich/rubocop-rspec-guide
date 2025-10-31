#!/usr/bin/env ruby
# frozen_string_literal: true

require "benchmark/ips"
require "rubocop"
require_relative "../lib/rubocop-rspec-guide"

# Create a sample RSpec file to analyze
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

# Configure RuboCop
RuboCop::ConfigStore.new

puts "=" * 80
puts "RuboCop::Cop::RSpec::Base Integration Benchmark"
puts "=" * 80
puts "\nSample code size: #{SAMPLE_CODE.lines.count} lines"
puts "Cops enabled: 6 RSpec cops"
puts "\n"

# Run benchmark
Benchmark.ips do |x|
  x.config(time: 10, warmup: 3)

  x.report("Process sample RSpec file") do
    runner = RuboCop::Runner.new(
      {format: "quiet"},
      RuboCop::ConfigStore.new
    )

    # Create a temporary file
    require "tempfile"
    file = Tempfile.new(["benchmark_spec", ".rb"])
    begin
      file.write(SAMPLE_CODE)
      file.flush
      runner.run([file.path])
    ensure
      file.close
      file.unlink
    end
  end

  x.compare!
end

#!/usr/bin/env ruby
# frozen_string_literal: true

# This script runs benchmarks and saves them as a baseline for future comparison
require_relative "benchmark_helper"

version = ENV["VERSION"] || "unknown"
output_file = "benchmark/baseline_v#{version}.txt"

puts "Saving baseline benchmark for version #{version}"
puts "Output file: #{output_file}"
puts ""

# Run cops_benchmark and save output
system("ruby benchmark/cops_benchmark.rb > #{output_file} 2>&1")

puts ""
puts "Baseline saved to #{output_file}"

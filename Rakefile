# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task default: %i[spec standard]

namespace :benchmark do
  desc "Run quick benchmarks for all cops (fast feedback, ~1 minute)"
  task :quick do
    ruby "benchmark/cops_benchmark.rb"
  end

  desc "Run performance benchmarks for all cops"
  task :cops do
    ruby "benchmark/cops_benchmark.rb"
  end

  desc "Run scalability benchmarks"
  task :scalability do
    ruby "benchmark/scalability_benchmark.rb"
  end

  desc "Run all benchmarks in quick mode (~2 minutes)"
  task all: [:cops, :scalability]

  desc "Run full benchmarks with accurate measurements (~5 minutes)"
  task :full do
    ENV["FULL_BENCHMARK"] = "1"
    Rake::Task["benchmark:all"].invoke
  end
end

desc "Run all benchmarks in quick mode"
task benchmark: "benchmark:all"

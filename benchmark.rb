#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "benchmark"
require "memory_profiler"
require "interval_tree"

# Simple data generator
def generate_intervals(count, max_range = 10000)
  count.times.map do
    start = rand(max_range)
    finish = start + rand(100) + 1
    start..finish
  end
end

# Test datasets (fixed seed for consistency)
srand(42)
datasets = {
  small: generate_intervals(1000),
  medium: generate_intervals(10000),
  large: generate_intervals(100000)
}

# Search queries
queries = {
  point: 5000..5000,
  small_range: 4900..5100,
  large_range: 2000..8000
}

puts " 🏗️ Construction Performance"
puts " ==========================="
construction_times = {}

datasets.each do |size, intervals|
  time = Benchmark.realtime do
    5.times { IntervalTree::Tree.new(intervals.dup) }
  end
  avg_time = (time / 5) * 1000 # Convert to milliseconds
  construction_times[size] = avg_time
  puts "  #{size.to_s.ljust(8)} (#{intervals.size} intervals): #{avg_time.round(2)}ms"
end

puts "\n 🔍 Search Performance"
puts " ==========================="
search_times = { materialized: {}, enumerated: {} }

datasets.each do |size, intervals|
  tree = IntervalTree::Tree.new(intervals)
  search_times[:materialized][size] = {}
  search_times[:enumerated][size] = {}

  queries.each do |query_type, query|
    # Test materialization (.to_a)
    time = Benchmark.realtime do
      100.times { tree.search(query).to_a }
    end
    avg_time = (time / 100) * 1000 # Convert to milliseconds
    search_times[:materialized][size][query_type] = avg_time
    puts "  #{size.to_s.ljust(8)} #{query_type.to_s.ljust(12)} (materialized): #{avg_time.round(3)}ms"

    # Test lazy enumeration (.each)
    time = Benchmark.realtime do
      100.times { tree.search(query).each { |_| nil } }
    end
    avg_time = (time / 100) * 1000 # Convert to milliseconds
    search_times[:enumerated][size][query_type] = avg_time
    puts "  #{size.to_s.ljust(8)} #{query_type.to_s.ljust(12)} (enumerated):  #{avg_time.round(3)}ms"
  end
end

puts "\n 🧠 Memory Usage "
puts " ==========================="
memory_data = { materialized: {}, enumerated: {} }

datasets.each do |size, intervals|
  puts " #{size.capitalize} dataset (#{intervals.size} intervals):"

  # Memory profile construction
  construction_report = MemoryProfiler.report do
    IntervalTree::Tree.new(intervals.dup)
  end

  puts "   Construction:"
  puts "     Total allocated: #{construction_report.total_allocated_memsize} bytes"
  puts "     Total objects: #{construction_report.total_allocated}"
  puts "     Retained objects: #{construction_report.total_retained}"

  # Memory profile search operations - materialized
  tree = IntervalTree::Tree.new(intervals)
  materialized_report = MemoryProfiler.report do
    100.times { tree.search(queries[:point]).to_a }
  end

  puts "   Search - Materialized (100 point queries):"
  puts "     Total allocated: #{materialized_report.total_allocated_memsize} bytes"
  puts "     Total objects: #{materialized_report.total_allocated}"
  puts "     Retained objects: #{materialized_report.total_retained}"

  # Memory profile search operations - enumerated
  enumerated_report = MemoryProfiler.report do
    100.times { tree.search(queries[:point]).each { |_| nil } }
  end

  puts "   Search - Enumerated (100 point queries):"
  puts "     Total allocated: #{enumerated_report.total_allocated_memsize} bytes"
  puts "     Total objects: #{enumerated_report.total_allocated}"
  puts "     Retained objects: #{enumerated_report.total_retained}\n"

  # Store memory data for summary calculations
  memory_data[:materialized][size] = materialized_report.total_allocated_memsize
  memory_data[:enumerated][size] = enumerated_report.total_allocated_memsize
end

puts "\n 🏁 Summary & Insights"
puts " ==========================="

# Performance scaling analysis
puts " Performance Scaling:"
small_construction = construction_times[:small]
medium_construction = construction_times[:medium]
large_construction = construction_times[:large]
puts "   Construction scales ~#{(medium_construction / small_construction).round(1)}x for 10x data, ~#{(large_construction / small_construction).round(1)}x for 100x data"

small_search = search_times[:materialized][:small][:point]
medium_search = search_times[:materialized][:medium][:point]
large_search = search_times[:materialized][:large][:point]
puts "   Search scales ~#{(medium_search / small_search).round(1)}x for 10x data, ~#{(large_search / small_search).round(1)}x for 100x data"

# Memory efficiency analysis
puts "\n Memory Efficiency (Enumerated vs Materialized):"
[:small, :medium, :large].each do |size|
  materialized_mem = memory_data[:materialized][size]
  enumerated_mem = memory_data[:enumerated][size]
  savings_percent = ((materialized_mem - enumerated_mem).to_f / materialized_mem * 100).round(1)
  puts "   #{size.capitalize} dataset:  #{savings_percent}% memory savings (#{materialized_mem} → #{enumerated_mem} bytes)"
end

# Performance comparison
puts "\n Enumerated vs Materialized Performance:"
materialized_avg = (search_times[:materialized][:small][:point] + search_times[:materialized][:medium][:point] + search_times[:materialized][:large][:point]) / 3
enumerated_avg = (search_times[:enumerated][:small][:point] + search_times[:enumerated][:medium][:point] + search_times[:enumerated][:large][:point]) / 3
performance_diff = ((materialized_avg - enumerated_avg).abs / materialized_avg * 100).round(2)

puts "   Materialized: #{materialized_avg.round(3)}ms avg"
puts "   Enumerated:   #{enumerated_avg.round(3)}ms avg"
puts "   Difference:   #{performance_diff}%"

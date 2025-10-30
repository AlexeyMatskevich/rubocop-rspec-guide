# Performance Benchmarks

This directory contains performance benchmarks for RuboCop RSpec Guide cops.

## Current Performance (v0.3.1)

Based on actual measurements on Ruby 3.4.7 (2025-10-30):

### Typical Files (10-20 lines, simple RSpec examples)

| Cop Name | Iterations/sec | Time per file | Status |
|----------|---------------|---------------|---------|
| MinimumBehavioralCoverage | 2,457 i/s | 407 μs | ⚡ Excellent |
| DynamicAttributeEvaluation | 2,423 i/s | 413 μs | ⚡ Excellent |
| ContextSetup | 2,040 i/s | 490 μs | ⚡ Excellent |
| HappyPathFirst | 2,003 i/s | 499 μs | ⚡ Excellent |
| DuplicateBeforeHooks | 1,626 i/s | 615 μs | ✅ Good |
| InvariantExamples | 1,504 i/s | 665 μs | ✅ Good |
| DuplicateLetValues | 1,499 i/s | 667 μs | ✅ Good |

**Real-world impact:** At 2,000 i/s average, scanning 100 typical spec files takes only **0.05 seconds** ⚡

### Large Files (Scalability)

| File Size | Iterations/sec | Time per file | Lines | Contexts |
|-----------|---------------|---------------|-------|----------|
| Small | 357 i/s | 2.8 ms | 87 | 5 |
| Medium | 167 i/s | 6.0 ms | 172 | 10 |
| Large | 73 i/s | 13.6 ms | 342 | 20 |

**Scalability:** Complexity is **O(n) - linear** ✅
- Doubling file size approximately doubles processing time
- No exponential degradation observed
- Slight overhead: 2x size = 2.1x time (expected behavior)

**Real-world impact:** At 100 i/s average for large files, scanning 100 large spec files takes **1 second** - acceptable for CI/CD.

## Performance Baseline

### Target Performance (based on measurements)

**Typical files (10-20 lines):**
- Expected: **1,500-2,500 i/s** (0.4-0.7 ms per file)
- Warning threshold: **< 1,000 i/s** (investigate if below)
- Critical threshold: **< 500 i/s** (requires optimization)

**Large files (300+ lines, 20+ contexts):**
- Expected: **70-150 i/s** (7-14 ms per file)
- Warning threshold: **< 50 i/s**
- Critical threshold: **< 25 i/s**

**Scalability:**
- Complexity: **O(n)** - linear scaling required
- Doubling file size should approximately double processing time
- Warning: > 2.5x increase (may indicate O(n²) behavior)
- Critical: > 5x increase (algorithmic problem)

**Memory usage:**
- Target: < 10 MB per large file (500+ lines)
- Warning: > 20 MB
- Critical: > 50 MB (memory leak suspected)

### Why These Numbers?

These baselines are established from actual measurements on production-quality code:

1. **1,500-2,500 i/s for typical files** allows scanning large codebases quickly
   - 1,000 files = 0.5 seconds at 2,000 i/s
   - This keeps CI/CD pipelines fast

2. **70-150 i/s for large files** is acceptable given complexity
   - Large files are rare in well-structured codebases
   - Still allows 100 large files in ~1 second

3. **O(n) complexity** prevents exponential slowdowns
   - Critical for maintaining performance as files grow
   - AST traversal is inherently O(n)

## Requirements

Install benchmark dependencies:

```bash
bundle install
```

## Running Benchmarks

### Quick Benchmark (recommended for development)

Run a fast benchmark for immediate feedback (~1 minute):

```bash
rake benchmark:quick
```

Or directly:

```bash
bundle exec ruby benchmark/cops_benchmark.rb
```

This uses shorter warmup (1s) and measurement (2s) times for quick feedback during development.

### Full Benchmark (for accurate measurements)

Run comprehensive benchmark with longer measurement times (~3 minutes):

```bash
FULL_BENCHMARK=1 rake benchmark
```

This uses longer warmup (2s) and measurement (5s) times for more accurate statistical analysis.

### All Cops Performance

Benchmark each cop individually:

```bash
bundle exec ruby benchmark/cops_benchmark.rb
```

This will benchmark each cop with both violation and non-violation cases, showing:
- Iterations per second (i/s)
- Microseconds per iteration (μs/i)
- Comparison between violation and non-violation cases
- Performance characteristics of each cop

### Scalability Testing

Test how cops perform with different file sizes:

```bash
bundle exec ruby benchmark/scalability_benchmark.rb
```

This benchmark tests:
- Performance with increasing number of contexts (5, 10, 20, 50)
- Performance with increasing number of examples (10, 25, 50, 100)
- Performance with nested contexts (3, 5, 10, 15 levels)
- Performance with duplicate examples (2, 5, 10, 15 duplicates)
- Memory usage for large files

### Using Rake Tasks

You can also run benchmarks using Rake:

```bash
# Run quick benchmarks (recommended)
rake benchmark:quick

# Run all benchmarks (full mode)
rake benchmark

# Run only cops benchmark
rake benchmark:cops

# Run only scalability benchmark
rake benchmark:scalability
```

## Understanding Results

### Iterations per Second (i/s)

Higher is better. This shows how many times per second the cop can analyze the given source code.

Example output:
```
MinimumBehavioralCoverage (with violation)      2.457k (± 1.7%) i/s  (407.05 μs/i)
MinimumBehavioralCoverage (without violation)   1.683k (± 1.4%) i/s  (594.34 μs/i)
```

This means:
- **2.457k i/s** = 2,457 iterations per second
- **(407.05 μs/i)** = 0.407 milliseconds per file
- **(± 1.7%)** = standard deviation (lower is more consistent)

At 2,457 i/s, the cop can analyze:
- 100 files in 0.04 seconds
- 1,000 files in 0.4 seconds
- 10,000 files in 4 seconds

### Comparison

The benchmark shows relative performance:
```
Comparison:
  MinimumBehavioralCoverage (with violation):     2456.7 i/s
  MinimumBehavioralCoverage (without violation):  1682.5 i/s - 1.46x slower
```

This is expected: finding and reporting violations takes slightly more time than simply traversing the AST.

### Memory Usage

Shows memory consumption in MB for processing large files:
```
RSpecGuide/MinimumBehavioralCoverage: 2.45 MB
```

This is the additional memory allocated during cop execution. Lower is better.

### Interpreting Results

**Excellent performance (⚡):**
- Typical files: > 2,000 i/s
- Large files: > 150 i/s
- No action needed

**Good performance (✅):**
- Typical files: 1,000-2,000 i/s
- Large files: 50-150 i/s
- Monitor, but acceptable

**Warning (⚠️):**
- Typical files: 500-1,000 i/s
- Large files: 25-50 i/s
- Consider optimization

**Critical (❌):**
- Typical files: < 500 i/s
- Large files: < 25 i/s
- Requires immediate optimization

## Optimization Tips

If a cop is performing poorly:

1. **Check AST traversal**: Use `def_node_matcher` instead of manual traversal
   ```ruby
   # Slow: manual traversal
   def on_block(node)
     node.children.each do |child|
       # ...
     end
   end
   
   # Fast: node matcher
   def_node_matcher :context_node?, <<~PATTERN
     (block (send nil? :context ...) ...)
   PATTERN
   ```

2. **Avoid redundant checks**: Cache results when possible
   ```ruby
   # Slow: recalculating
   def check(node)
     if expensive_operation(node)
       # ...
     end
   end
   
   # Fast: memoization
   def check(node)
     @cache ||= {}
     @cache[node] ||= expensive_operation(node)
   end
   ```

3. **Limit scope**: Only traverse relevant parts of the AST
   ```ruby
   # Slow: checking everything
   def on_send(node)
     check_all_sends(node)
   end
   
   # Fast: early return
   def on_send(node)
     return unless relevant_method?(node)
     check_specific_send(node)
   end
   ```

4. **Use early returns**: Exit as soon as violation is found
   ```ruby
   # Slow: checking everything
   def check_all_contexts(contexts)
     violations = []
     contexts.each { |ctx| violations << check(ctx) }
     violations
   end
   
   # Fast: early return
   def check_all_contexts(contexts)
     contexts.each { |ctx| return ctx if violation?(ctx) }
     nil
   end
   ```

## Continuous Monitoring

### Before Making Changes

Run benchmarks and save baseline:

```bash
bundle exec ruby benchmark/cops_benchmark.rb > before.txt
```

### After Making Changes

Run benchmarks again and compare:

```bash
bundle exec ruby benchmark/cops_benchmark.rb > after.txt
diff before.txt after.txt
```

### Regression Testing

Compare with official baseline:

```bash
bundle exec ruby benchmark/cops_benchmark.rb > current.txt
diff benchmark/baseline_v0.3.1.txt current.txt
```

Significant deviations (> 20% slower) should be investigated.

## CI/CD Integration

Add to your CI pipeline to catch performance regressions:

```yaml
# .github/workflows/ci.yml
- name: Run performance benchmarks
  run: |
    rake benchmark:quick
    # Fail if any cop is critically slow
    # (implementation depends on your CI setup)
```

## Baseline Files

Baseline files capture performance at specific versions:

- `baseline_v0.3.1.txt` - Current baseline (Ruby 3.4.7, 2025-10-30)

These files are tracked in git to enable historical comparison.

## Contributing

When adding new cops:

1. Run benchmarks for the new cop
2. Ensure performance meets baseline (> 1,000 i/s for typical files)
3. Document any performance considerations
4. Update baseline file if adding significant new functionality

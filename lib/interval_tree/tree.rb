# frozen_string_literal: true

module IntervalTree
  class Tree
    attr_reader :root

    # Constructs a binary search tree from an array of intervals
    #
    # @param intervals [Array<Range>] the intervals to construct the tree from
    # @param sorted [Boolean] specify if `intervals` is already sorted
    def initialize(intervals, sorted: false)
      intervals.sort_by! { |r| [r.min, r.max] } unless sorted
      @root = construct(intervals, 0, intervals.length - 1)
    end

    # Search for all intervals in the tree that intersect with `range`
    #
    # @param interval [Range] the search interval
    # @return [SearchResultsEnumerator] enumerator for lazy evaluation of search results
    def search(interval)
      interval = interval.is_a?(Range) ? interval : (interval..interval)

      # Cache interval.min to avoid repeated method calls during traversal
      begin
        interval_min = interval.min
      # Handle edge case of beginless ranges
      rescue RangeError
        interval_min = interval.begin
      end

      SearchResultsEnumerator.new(root, interval, interval_min)
    end

    private

    def construct(ranges, start_idx, end_idx)
      return nil if start_idx > end_idx

      # find center point
      length = end_idx - start_idx + 1
      center = start_idx + length / 2
      range = ranges[center]

      # construct subtrees
      left = construct(ranges, start_idx, center - 1)
      right = construct(ranges, center + 1, end_idx)

      max_val = range.max
      max_val = [max_val, left.max].max if left
      max_val = [max_val, right.max].max if right

      Node.new(range, left, right, max_val)
    end

  end
end

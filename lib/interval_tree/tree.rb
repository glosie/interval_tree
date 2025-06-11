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
    # @return [Array] the array of search results
    def search(interval)
      interval = interval.is_a?(Range) ? interval : (interval..interval)
      results = []

      # Cache interval.min to avoid repeated method calls during traversal
      # Handle edge case of beginless ranges
      begin
        interval_min = interval.min
      rescue RangeError
        interval_min = interval.begin
      end
      search_nodes(interval, interval_min, root, results)
      results
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

    # Performs a recursive membership query on the current node and it's
    # subtrees
    #
    # @param interval [Range] the range query
    # @param interval_min [Integer] cached minimum value of the interval
    # @param node [IntervalTree::Node] the current "root" node
    # @param results [Array] the accumulated results
    def search_nodes(interval, interval_min, node, results)
      return if node.nil?

      left_subtree = node.left
      right_subtree = node.right

      # search left subtree
      if left_subtree && (interval_min <= left_subtree.max)
        search_nodes(interval, interval_min, left_subtree, results)
      end

      # add current interval to results if it overlaps
      results << node.range if node.overlaps?(interval)

      # search right subtree
      if right_subtree && (interval_min <= right_subtree.max)
        search_nodes(interval, interval_min, right_subtree, results)
      end
    end
  end
end

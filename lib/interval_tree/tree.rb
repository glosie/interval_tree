module IntervalTree
  class Tree
    attr_reader :root

    # Constructs a binary search tree from an array of intervals
    #
    # @param intervals [Array<Range>] the intervals to construct the tree from
    # @param sorted [Boolean] specify if `intervals` is already sorted
    def initialize(intervals, sorted: false)
      intervals.sort_by! { |r| [r.min, r.max] } unless sorted
      @root = construct(intervals)
    end

    # Search for all intervals in the tree that intersect with `range`
    #
    # @param q [Range] the range to search for
    # @return [Array] the array of search results
    def search(q)
      q = q.is_a?(Range) ? q : (q..q)
      results = []

      search_nodes(q, root, results)
      results
    end

    private

    def construct(ranges)
      return nil if ranges.empty?

      # find center point
      center = ranges.length / 2
      range  = ranges[center]

      # construct subtrees
      left  = construct(ranges.slice(0, center))
      right = construct(ranges[(center + 1)..-1])

      array = [range, left, right].compact

      Node.new(
        range: range,
        left: left,
        right: right,
        max: array.map(&:max).max  # subtree max
      )
    end

    # Performs a recursive membership query on the current node and it's
    # subtrees
    #
    # @param q [Range] the range query
    # @param node [IntervalTree::Node] the current "root" node
    # @param results [Array] the accumulated results
    def search_nodes(q, node, results)
      return if node.nil?

      left = node.left
      right = node.right

      # search left children
      search_nodes(q, left, results) if left && (q.min <= left.max)

      # add current interval to results if it overlaps
      results << node.range if node.overlaps?(q)

      # search right children
      search_nodes(q, right, results) if right && (q.min <= right.max)
    end
  end
end

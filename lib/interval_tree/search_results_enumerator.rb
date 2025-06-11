# frozen_string_literal: true

module IntervalTree
  # Enumerator for search results that provides lazy evaluation capabilities.
  class SearchResultsEnumerator
    include Enumerable

    def initialize(root, interval, interval_min)
      @root = root
      @interval = interval
      @interval_min = interval_min
    end

    # Enumerate through search results lazily
    #
    # @param block [Proc] optional block to process each result
    # @return [Enumerator] if no block given
    def each(&block)
      return enum_for(:each) unless block_given?

      traverse(@root, &block)
    end

    # Check if there are no results
    #
    # @return [Boolean] true if no results exist
    def empty?
      !any?
    end

    # Compare with another enumerable
    #
    # @param other [Enumerable] other enumerable to compare with
    # @return [Boolean] true if both contain same elements in same order
    def ==(other)
      to_a == Array(other)
    end

    # Count results with memoization for performance
    #
    # @return [Integer] number of matching intervals
    def count
      @cached_count ||= begin
        count = 0
        traverse(@root) { |_| count += 1 }
        count
      end
    end

    # Provide size/length methods (delegate to memoized count)
    alias_method :size, :count
    alias_method :length, :count

    private

    # Core traversal logic
    #
    # @param node [IntervalTree::Node] current node to traverse
    # @param block [Proc] block to call for each matching interval
    def traverse(node, &block)
      return if node.nil?

      left_subtree = node.left
      right_subtree = node.right

      # search left subtree
      if left_subtree && (@interval_min <= left_subtree.max)
        traverse(left_subtree, &block)
      end

      # process current interval if it overlaps
      block.call(node.range) if node.overlaps?(@interval)

      # search right subtree
      if right_subtree && (@interval_min <= right_subtree.max)
        traverse(right_subtree, &block)
      end
    end
  end
end

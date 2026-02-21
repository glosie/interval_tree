# frozen_string_literal: true

module IntervalTree
  # Search results collection that provides lazy evaluation capabilities.
  class SearchResults
    include Enumerable

    def initialize(root, interval, interval_min, interval_max)
      @root = root
      @interval = interval
      @interval_min = interval_min
      @interval_max = interval_max
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
    # When called without arguments or a block, returns the memoized total
    # count. Otherwise delegates to Enumerable#count to support filtered
    # counting (e.g. count { |r| r.min >= 5 }) and value counting
    # (e.g. count(3..7)).
    #
    # @return [Integer] number of matching intervals
    def count(*args, &block)
      if args.empty? && block.nil?
        @cached_count ||= begin
          c = 0
          traverse(@root) { |_| c += 1 }
          c
        end
      else
        super
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

      # if search interval ends before this node starts, nothing here
      # or to the right can overlap (BST is sorted by range.min)
      return if @interval_max < node.range.min

      # process current interval if it overlaps
      block.call(node.range) if node.overlaps?(@interval)

      # search right subtree
      if right_subtree && (@interval_min <= right_subtree.max)
        traverse(right_subtree, &block)
      end
    end
  end
end

# frozen_string_literal: true

module IntervalTree
  class Tree
    attr_reader :root

    # Constructs a binary search tree from an array of intervals
    #
    # @param intervals [Array<Range>] the intervals to construct the tree from
    # @param sorted [Boolean] specify if `intervals` is already sorted
    def initialize(intervals, sorted: false)
      intervals = intervals.sort_by { |r| [r.min, r.max] } unless sorted
      @root = construct(intervals, 0, intervals.length - 1)
    end

    # Search for all intervals in the tree that intersect with `range`
    #
    # @param interval [Range] the search interval
    # @return [SearchResults] lazy enumerable of matching intervals
    def search(interval)
      raise ArgumentError, "search interval cannot be nil" if interval.nil?

      interval = interval.is_a?(Range) ? interval : (interval..interval)

      # Normalize beginless/endless ranges to use infinity bounds so that
      # .min/.max never raise and nil never propagates into comparisons
      range_begin = interval.begin || -Float::INFINITY
      range_end = interval.end || Float::INFINITY

      search_range = interval.exclude_end? ? (range_begin...range_end) : (range_begin..range_end)

      SearchResults.new(root, search_range, range_begin, range_end)
    end

    def insert(range)
      @root = insert_node(@root, range)
      self
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

      height = 1 + [node_height(left), node_height(right)].max
      Node.new(range, left, right, max_val, height)
    end

    def node_height(node)
      node&.height || 0
    end

    def balance_factor(node)
      node_height(node.left) - node_height(node.right)
    end

    def refresh(node)
      max_val = node.range.max
      max_val = [max_val, node.left.max].max if node.left
      max_val = [max_val, node.right.max].max if node.right
      node.max = max_val
      node.height = 1 + [node_height(node.left), node_height(node.right)].max
      node
    end

    def rotate_left(node)
      new_root = node.right
      node.right = new_root.left
      new_root.left = node
      refresh(node)
      refresh(new_root)
      new_root
    end

    def rotate_right(node)
      new_root = node.left
      node.left = new_root.right
      new_root.right = node
      refresh(node)
      refresh(new_root)
      new_root
    end

    def rebalance(node)
      bf = balance_factor(node)

      if bf > 1
        if balance_factor(node.left) < 0
          node.left = rotate_left(node.left)
        end
        rotate_right(node)
      elsif bf < -1
        if balance_factor(node.right) > 0
          node.right = rotate_right(node.right)
        end
        rotate_left(node)
      else
        node
      end
    end

    def insert_node(node, range)
      return Node.new(range, nil, nil, range.max, 1) if node.nil?

      cmp = compare_sort_keys(range, node.range)

      if cmp <= 0
        node.left = insert_node(node.left, range)
      else
        node.right = insert_node(node.right, range)
      end

      refresh(node)
      rebalance(node)
    end

    def compare_sort_keys(a, b)
      cmp = a.min <=> b.min
      cmp == 0 ? a.max <=> b.max : cmp
    end

  end
end

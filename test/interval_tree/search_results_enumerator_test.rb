require "test_helper"

module IntervalTree
  class SearchResultsEnumeratorTest < Minitest::Test
    def setup
      # Create nodes directly without going through Tree:
      #       5..6
      #      /    \
      #   2..4    7..8
      #   /  \
      # 1..3 3..8
      @node1 = Node.new(1..3, nil, nil, 3)
      @node2 = Node.new(3..8, nil, nil, 8)
      @node3 = Node.new(2..4, @node1, @node2, 8)
      @node4 = Node.new(7..8, nil, nil, 8)
      @root = Node.new(5..6, @node3, @node4, 8)

      @search_interval = 2..6
      @results = SearchResultsEnumerator.new(@root, @search_interval, @search_interval.min)
    end

    def test_implements_enumerable
      assert_kind_of Enumerable, @results
      assert_respond_to @results, :each
      assert_respond_to @results, :to_a
      assert_respond_to @results, :first
      assert_respond_to @results, :empty?
      assert_respond_to @results, :count
      assert_respond_to @results, :size
      assert_respond_to @results, :length
    end

    def test_each_with_block_yields_all_results
      collected = []
      @results.each { |range| collected << range }

      expected = [1..3, 2..4, 3..8, 5..6]
      assert_equal expected, collected
    end

    def test_each_without_block_returns_enumerator
      enumerator = @results.each
      assert_kind_of Enumerator, enumerator
      expected = [1..3, 2..4, 3..8, 5..6]
      assert_equal expected, enumerator.to_a
    end

    def test_to_a_returns_array_of_results
      expected = [1..3, 2..4, 3..8, 5..6]
      assert_equal expected, @results.to_a
    end

    def test_first_without_argument_returns_first_result
      assert_equal 1..3, @results.first
    end

    def test_first_without_argument_on_empty_results_returns_nil
      empty_results = SearchResultsEnumerator.new(@root, 10..20, 10)
      assert_nil empty_results.first
    end

    def test_first_with_0_returns_empty_array
      assert_equal [], @results.first(0)
    end

    def test_first_with_argument_returns_first_n_results
      assert_equal [1..3, 2..4], @results.first(2)
      assert_equal [1..3, 2..4, 3..8], @results.first(3)
      assert_equal [1..3, 2..4, 3..8, 5..6], @results.first(10)
    end

    def test_empty_returns_false_when_results_exist
      refute @results.empty?
    end

    def test_empty_returns_true_when_no_results
      # Search for interval that doesn't overlap with any nodes
      no_match_interval = 20..30
      empty_results = SearchResultsEnumerator.new(@root, no_match_interval, no_match_interval.min)
      assert empty_results.empty?
    end

    def test_count_size_length_return_number_of_results
      assert_equal 4, @results.count
      assert_equal 4, @results.size
      assert_equal 4, @results.length
    end

    def test_count_size_length_return_zero_for_empty_results
      no_match_interval = 20..30
      empty_results = SearchResultsEnumerator.new(@root, no_match_interval, no_match_interval.min)
      assert_equal 0, empty_results.count
      assert_equal 0, empty_results.size
      assert_equal 0, empty_results.length
    end

    def test_equality_with_array
      expected = [1..3, 2..4, 3..8, 5..6]
      assert_equal expected, @results.to_a
      assert @results == expected
    end

    def test_equality_with_empty_array
      no_match_interval = 20..30
      empty_results = SearchResultsEnumerator.new(@root, no_match_interval, no_match_interval.min)
      assert_equal [], empty_results.to_a
      assert empty_results == []
    end

    def test_supports_enumerable_methods
      # map
      mapped_results = @results.map { |r| r.max }
      assert_equal [3, 4, 8, 6], mapped_results

      # select
      filtered_results = @results.select { |r| r.max > 5 }
      assert_equal [3..8, 5..6], filtered_results

      # any?
      assert @results.any? { |r| r.max == 4 }
      refute @results.any? { |r| r.max == 20 }
    end

    def test_lazy_evaluation_stops_early
      first_result = nil
      @results.each do |range|
        first_result = range
        break
      end

      assert_equal 1..3, first_result
    end

    def test_enumerator_consistency_across_multiple_calls
      first_to_a = @results.to_a
      second_to_a = @results.to_a

      assert_equal first_to_a, second_to_a

      first_count = @results.count
      second_count = @results.count

      assert_equal first_count, second_count
    end

    def test_handles_complex_overlapping_scenarios
      # Create a more complex tree structure
      # Ranges: [2..3, 3..5, 4..10, 5..7, 6..10, 7..9, 9..11]
      n1 = Node.new(2..3, nil, nil, 3)
      n2 = Node.new(4..10, nil, nil, 10)
      n3 = Node.new(3..5, n1, n2, 10)
      n4 = Node.new(6..10, nil, nil, 10)
      n5 = Node.new(7..9, nil, nil, 9)
      n6 = Node.new(9..11, nil, nil, 11)
      n7 = Node.new(5..7, n4, n5, 10)
      complex_root = Node.new(n6.range, n3, n7, 11)

      search_interval = 4..8
      results = SearchResultsEnumerator.new(complex_root, search_interval, search_interval.min)

      # Expected overlapping ranges with 4..8: [3..5, 4..10, 5..7, 6..10, 7..9]
      expected = [3..5, 4..10, 5..7, 6..10, 7..9]
      assert_equal expected.sort_by(&:min), results.sort_by(&:min)
      assert_equal 5, results.count
      refute results.empty?
    end

    def test_first_method_edge_cases
      # Test first(0)
      assert_equal [], @results.first(0)

      # Test first(1)
      assert_equal [1..3], @results.first(1)

      # Test first with number larger than available results
      large_n_results = @results.first(100)
      assert_equal @results.to_a, large_n_results
    end

    def test_responds_to_enumerable_query_methods
      assert_respond_to @results, :any?
      assert_respond_to @results, :all?
      assert_respond_to @results, :none?
      assert_respond_to @results, :find
      assert_respond_to @results, :select
      assert_respond_to @results, :reject
      assert_respond_to @results, :map
      assert_respond_to @results, :collect
    end

    def test_works_with_nil_root
      # empty tree
      nil_results = SearchResultsEnumerator.new(nil, 1..10, 1)

      assert nil_results.empty?
      assert_equal [], nil_results.to_a
      assert_equal 0, nil_results.count
      assert_nil nil_results.first
    end

    def test_works_with_single_node
      single_node = Node.new(5..10, nil, nil, 10)
      single_results = SearchResultsEnumerator.new(single_node, 7..8, 7)

      assert_equal [5..10], single_results.to_a
      assert_equal 1, single_results.count
      refute single_results.empty?
    end

    def test_traversal_order_is_consistent
      # Verify that the traversal order is consistent (in-order traversal)
      collected_ranges = []
      @results.each { |range| collected_ranges << range }

      # Should always return the same order
      second_collection = []
      @results.each { |range| second_collection << range }

      assert_equal collected_ranges, second_collection
    end
  end
end

require "test_helper"
module IntervalTree
  class TreeTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil IntervalTree::VERSION
    end

    def test_that_it_recieves_empty_arrays
      t = Tree.new([])
      assert_nil t.root
    end

    def test_that_it_contructs_a_tree_from_a_single_range
      t = Tree.new([1..10])
      assert_equal 1..10, t.root.range
      assert_nil t.root.left
      assert_nil t.root.right
      assert_equal 10, t.root.max
    end

    def test_that_it_constructs_a_tree_from_multiple_simple_ranges
      t = Tree.new([1..2, 3..4, 5..6, 7..8, 8..9, 3..8])
      left_child = t.root.left
      left_child_left_grandchild = left_child.left
      left_child_right_grandchild = left_child.right
      right_child = t.root.right

      assert_equal 5..6, t.root.range
      assert_equal 3..4, left_child.range
      assert_equal 1..2, left_child_left_grandchild.range
      assert_nil left_child_left_grandchild.left
      assert_nil left_child_left_grandchild.right
      assert_equal 3..8, left_child_right_grandchild.range
      assert_equal 8..9, right_child.range
      assert_equal 7..8, right_child.left.range
      assert_nil right_child.right

      assert_equal 9, t.root.max
      assert_equal 8, left_child.max
      assert_equal 2, left_child_left_grandchild.max
      assert_equal 8, left_child_right_grandchild.max
      assert_equal 9, right_child.max
    end

    def test_that_it_handles_date_ranges
      d1 = Time.new(2017, 4, 10, 12)
      d2 = Time.new(2018, 4, 10, 12)
      d3 = Time.new(2019, 4, 10, 12)
      t = Tree.new([d1..d2, d2..d3, d1..d3])

      assert_equal d1..d3, t.root.range

      assert_equal d2, t.root.left.max
      assert_equal d1..d2, t.root.left.range

      assert_equal d3, t.root.right.max
      assert_equal d1..d3, t.root.range
    end

    def test_search_in_empty_ranges
      t = Tree.new([])

      assert_empty t.search(0)
      assert_empty t.search(0..0)
      assert_empty t.search(1..3)
      assert_empty t.search(1..1)
    end

    def test_search_nil_raises_argument_error
      t = Tree.new([1..3, 4..6, 7..9])
      assert_raises(ArgumentError) { t.search(nil) }

      empty_tree = Tree.new([])
      assert_raises(ArgumentError) { empty_tree.search(nil) }
    end

    def test_search_beginless_range
      t = Tree.new([1..3, 4..6, 7..9])
      assert_equal t.search(..5), [1..3, 4..6]
    end

    def test_search_beginless_exclusive_range
      t = Tree.new([1..3, 4..6, 7..9])
      assert_equal t.search(...4), [1..3]
    end

    def test_search_endless_range
      t = Tree.new([1..3, 4..6, 7..9])
      assert_equal t.search(5..), [4..6, 7..9]
    end

    def test_find_overlapping_intervals
      t = Tree.new([2..3, 3..5, 4..10, 5..7, 6..10, 7..9, 9..11])
      assert_equal t.search(4..8), [3..5, 4..10, 5..7, 6..10, 7..9]
    end

    def test_search_returns_search_results
      t = Tree.new([1..3, 2..4, 5..7, 6..8])
      results = t.search(2..6)

      assert_kind_of IntervalTree::SearchResults, results
    end

    def test_does_not_mutate_input_array
      intervals = [5..6, 1..2, 3..4]
      original = intervals.dup
      Tree.new(intervals)

      assert_equal original, intervals
    end

    def test_accepts_frozen_array
      intervals = [5..6, 1..2, 3..4].freeze

      Tree.new(intervals)
    end

    # --- Insert tests ---

    def test_insert_into_empty_tree
      t = Tree.new([])
      t.insert(1..5)

      assert_equal 1..5, t.root.range
      assert_nil t.root.left
      assert_nil t.root.right
      assert_equal 5, t.root.max
      assert_equal 1, t.root.height
    end

    def test_insert_maintains_bst_ordering
      t = Tree.new([])
      [3..4, 1..2, 5..6, 2..3, 4..5].each { |r| t.insert(r) }

      ranges = collect_inorder(t.root)
      sort_keys = ranges.map { |r| [r.min, r.max] }
      assert_equal sort_keys.sort, sort_keys
    end

    def test_insert_maintains_avl_invariants
      t = Tree.new([])
      (1..20).each { |i| t.insert(i..(i + 5)) }
      assert_avl_invariants(t.root)
    end

    def test_insert_returns_self_for_chaining
      t = Tree.new([])
      result = t.insert(1..5).insert(2..6)
      assert_equal t, result
      assert_equal 2, t.search(1..10).count
    end

    def test_insert_duplicate_ranges
      t = Tree.new([])
      t.insert(1..5)
      t.insert(1..5)
      assert_equal [1..5, 1..5], t.search(1..5).to_a
    end

    def test_insert_search_finds_new_range
      t = Tree.new([1..3, 5..7])
      t.insert(4..6)
      assert_includes t.search(4..6).to_a, 4..6
    end

    # --- Delete tests ---

    def test_delete_leaf_node
      t = Tree.new([1..2, 3..4, 5..6])
      t.delete(1..2)
      refute_includes t.search(0..10).to_a, 1..2
      assert_avl_invariants(t.root)
    end

    def test_delete_node_with_one_child
      t = Tree.new([1..2, 3..4, 5..6, 7..8])
      t.delete(3..4)
      refute_includes t.search(0..10).to_a, 3..4
      assert_includes t.search(0..10).to_a, 1..2
      assert_avl_invariants(t.root)
    end

    def test_delete_node_with_two_children
      t = Tree.new([1..2, 3..4, 5..6, 7..8, 9..10])
      root_range = t.root.range
      t.delete(root_range)
      refute_includes t.search(0..20).to_a, root_range
      assert_equal 4, t.search(0..20).count
      assert_avl_invariants(t.root)
    end

    def test_delete_root_node
      t = Tree.new([1..3, 4..6, 7..9])
      root_range = t.root.range
      t.delete(root_range)
      refute_includes t.search(0..20).to_a, root_range
      assert_avl_invariants(t.root)
    end

    def test_delete_returns_deleted_range
      t = Tree.new([1..3, 4..6, 7..9])
      result = t.delete(4..6)
      assert_equal 4..6, result
    end

    def test_delete_nonexistent_returns_nil
      t = Tree.new([1..3, 4..6, 7..9])
      result = t.delete(10..20)
      assert_nil result
    end

    def test_delete_maintains_avl_invariants
      t = Tree.new([])
      ranges = (1..20).map { |i| i..(i + 5) }
      ranges.each { |r| t.insert(r) }

      ranges.shuffle(random: Random.new(42)).first(10).each do |r|
        t.delete(r)
        assert_avl_invariants(t.root)
      end
    end

    def test_delete_removed_from_search
      t = Tree.new([1..3, 4..6, 7..9])
      t.delete(4..6)
      refute_includes t.search(4..6).to_a, 4..6
    end

    def test_delete_one_of_duplicates
      t = Tree.new([1..5, 1..5])
      t.delete(1..5)
      assert_equal [1..5], t.search(1..5).to_a
    end

    def test_delete_single_node_tree
      t = Tree.new([1..5])
      t.delete(1..5)
      assert_nil t.root
    end

    def test_delete_from_empty_tree
      t = Tree.new([])
      result = t.delete(1..5)
      assert_nil result
    end

    def test_delete_respects_exclude_end
      t = Tree.new([1...6])
      result = t.delete(1..5)
      assert_nil result
      assert_includes t.search(1..5).to_a, 1...6
    end

    def test_delete_same_sort_key_different_exclude_end
      t = Tree.new([])
      t.insert(1...6)
      t.insert(1..5)

      result = t.delete(1..5)
      assert_equal 1..5, result
      assert_equal [1...6], t.search(1..5).to_a
      assert_avl_invariants(t.root)
    end

    def test_delete_same_sort_key_constructor_built
      t = Tree.new([1..5, 1...6])
      result = t.delete(1..5)
      assert_equal 1..5, result
      assert_equal [1...6], t.search(1..5).to_a
      assert_avl_invariants(t.root) if t.root
    end

    def test_delete_successor_with_same_sort_key_different_exclude_end
      t = Tree.new([])
      [5..10, 3..4, 7...9, 7..8].each { |r| t.insert(r) }

      t.delete(5..10)
      refute_includes t.search(0..20).to_a, 5..10
      assert_avl_invariants(t.root)

      # no duplicates — 7..8 should appear exactly once
      results = t.search(7..8).to_a
      assert_equal 1, results.count(7..8), "7..8 should appear exactly once after delete"
    end

    # --- Integration test ---

    def test_random_insert_delete_stress
      rng = Random.new(12345)
      t = Tree.new([])
      brute = []

      100.times do
        if brute.empty? || rng.rand < 0.7
          a = rng.rand(100)
          b = a + rng.rand(20) + 1
          range = a..b
          t.insert(range)
          brute << range
        else
          range = brute.sample(random: rng)
          deleted = t.delete(range)
          assert_equal range, deleted
          idx = brute.index(range)
          brute.delete_at(idx)
        end

        assert_avl_invariants(t.root)
      end

      if brute.any?
        all_min = brute.map(&:min).min
        all_max = brute.map(&:max).max
        tree_results = t.search(all_min..all_max).to_a.sort_by { |r| [r.min, r.max] }
        brute_sorted = brute.sort_by { |r| [r.min, r.max] }
        assert_equal brute_sorted, tree_results
      end
    end

    private

    def assert_avl_invariants(node, min_key = nil, max_key = nil)
      return if node.nil?

      key = [node.range.min, node.range.max]

      if min_key
        assert((min_key <=> key) <= 0, "BST violation: #{min_key} should be <= #{key}")
      end
      if max_key
        assert((key <=> max_key) <= 0, "BST violation: #{key} should be <= #{max_key}")
      end

      expected_max = node.range.max
      expected_max = [expected_max, node.left.max].max if node.left
      expected_max = [expected_max, node.right.max].max if node.right
      assert_equal expected_max, node.max, "Max violation at node #{node.range}"

      left_h = node.left&.height || 0
      right_h = node.right&.height || 0
      expected_height = 1 + [left_h, right_h].max
      assert_equal expected_height, node.height, "Height violation at node #{node.range}"

      bf = (left_h - right_h).abs
      assert bf <= 1, "Balance violation at node #{node.range}: bf=#{bf}"

      assert_avl_invariants(node.left, min_key, key)
      assert_avl_invariants(node.right, key, max_key)
    end

    def collect_inorder(node)
      return [] if node.nil?
      collect_inorder(node.left) + [node.range] + collect_inorder(node.right)
    end
  end
end

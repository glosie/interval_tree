require 'test_helper'
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
      assert_empty t.search(nil)
      assert_empty t.search(0..0)
      assert_empty t.search(1..3)
      assert_empty t.search(1..1)
    end

    def test_find_overlapping_intervals
      t = Tree.new([2..3, 3..5, 4..10, 5..7, 6..10, 7..9, 9..11])
      assert_equal t.search(4..8), [3..5, 4..10, 5..7, 6..10, 7..9]
    end
  end
end

# frozen_string_literal: true

require "test_helper"

class IntervalTree::NodeTest < Minitest::Test
  def setup
    @range_1_5 = (1..5)
    @range_3_7 = (3..7)
    @range_8_10 = (8..10)
    @range_0_2 = (0..2)
    @range_6_9 = (6..9)
  end

  def test_node_creation
    left_child = IntervalTree::Node.new(@range_0_2)
    right_child = IntervalTree::Node.new(@range_8_10)
    parent = IntervalTree::Node.new(@range_3_7, left_child, right_child, 10)

    assert_equal @range_3_7, parent.range
    assert_equal left_child, parent.left
    assert_equal right_child, parent.right
    assert_equal 10, parent.max
  end

  def test_overlaps_with_overlapping_ranges
    node = IntervalTree::Node.new(@range_1_5)

    assert node.overlaps?(@range_3_7), "Ranges (1..5) and (3..7) should overlap"
    assert node.overlaps?(@range_0_2), "Ranges (1..5) and (0..2) should overlap"
    assert node.overlaps?(4..6), "Ranges (1..5) and (4..6) should overlap"
    assert node.overlaps?(5..8), "Ranges (1..5) and (5..8) should overlap"
    assert node.overlaps?(0..1), "Ranges (1..5) and (0..1) should overlap"
  end

  def test_overlaps_with_non_overlapping_ranges
    node = IntervalTree::Node.new(@range_1_5)

    refute node.overlaps?(@range_8_10), "Ranges (1..5) and (8..10) should not overlap"
    refute node.overlaps?(6..9), "Ranges (1..5) and (6..9) should not overlap"
    refute node.overlaps?(0..0), "Ranges (1..5) and (0..0) should not overlap"
    refute node.overlaps?(-5..-1), "Ranges (1..5) and (-5..-1) should not overlap"
  end

  def test_overlaps_with_identical_ranges
    node = IntervalTree::Node.new(@range_1_5)

    assert node.overlaps?(@range_1_5), "Identical ranges should overlap"
    assert node.overlaps?(1..5), "Identical ranges should overlap"
  end

  def test_overlaps_with_contained_ranges
    node = IntervalTree::Node.new(@range_1_5)

    assert node.overlaps?(2..4), "Range (2..4) should overlap with (1..5)"
    assert node.overlaps?(1..3), "Range (1..3) should overlap with (1..5)"
    assert node.overlaps?(3..5), "Range (3..5) should overlap with (1..5)"
  end

  def test_overlaps_with_containing_ranges
    node = IntervalTree::Node.new(2..4)

    assert node.overlaps?(@range_1_5), "Range (2..4) should overlap with containing range (1..5)"
    assert node.overlaps?(0..10), "Range (2..4) should overlap with containing range (0..10)"
  end

  def test_overlaps_with_edge_cases
    node = IntervalTree::Node.new(@range_1_5)

    # Test edge touching cases
    assert node.overlaps?(5..8), "Ranges touching at endpoint should overlap"
    assert node.overlaps?(0..1), "Ranges touching at startpoint should overlap"

    # Test single point ranges
    assert node.overlaps?(3..3), "Single point range within should overlap"
    assert node.overlaps?(1..1), "Single point at start should overlap"
    assert node.overlaps?(5..5), "Single point at end should overlap"

    refute node.overlaps?(6..6), "Single point after range should not overlap"
    refute node.overlaps?(0..0), "Single point before range should not overlap"
  end

  def test_overlaps_with_negative_ranges
    node = IntervalTree::Node.new(-5..-1)

    assert node.overlaps?(-7..-3), "Negative ranges should overlap correctly"
    assert node.overlaps?(-3..2), "Negative to positive range should overlap"
    refute node.overlaps?(1..5), "Non-overlapping positive range should not overlap"
  end

  def test_overlaps_with_float_ranges
    node = IntervalTree::Node.new(1.5..3.5)

    assert node.overlaps?(2.0..4.0), "Float ranges should overlap correctly"
    assert node.overlaps?(0.5..2.0), "Float ranges should overlap correctly"
    refute node.overlaps?(4.0..5.0), "Non-overlapping float ranges should not overlap"
  end

  def test_node_with_complex_tree_structure
    leaf1 = IntervalTree::Node.new(1..2, nil, nil, 2)
    leaf2 = IntervalTree::Node.new(4..5, nil, nil, 5)
    leaf3 = IntervalTree::Node.new(7..8, nil, nil, 8)
    internal1 = IntervalTree::Node.new(2..3, leaf1, leaf2, 5)
    root = IntervalTree::Node.new(5..6, internal1, leaf3, 8)

    assert_equal (5..6), root.range
    assert_equal internal1, root.left
    assert_equal leaf3, root.right
    assert_equal 8, root.max

    assert root.overlaps?(4..7), "Root should overlap with query range"
    assert internal1.overlaps?(1..4), "Internal node should overlap with query range"
    refute leaf1.overlaps?(6..9), "Leaf should not overlap with non-overlapping range"
  end
end

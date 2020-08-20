# frozen_string_literal: true

module IntervalTree
  class Node
    attr_reader :range, :left, :right, :max

    def initialize(range:, left:, right:, max: nil)
      @range = range
      @left = left
      @right = right
      @max = max || range.max
    end

    def overlaps?(other)
      range.min <= other.max && range.max >= other.min
    end
  end
end

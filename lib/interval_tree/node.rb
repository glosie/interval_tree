# frozen_string_literal: true

module IntervalTree
  class Node
    attr_reader :range, :left, :right, :min, :max

    def initialize(range:, left:, right:, min: nil, max: nil)
      @range = range
      @left = left
      @right = right
      @min = min || range.min
      @max = max || range.max
    end

    def overlaps?(other)
      range.min <= other.max && range.max >= other.min
    end
  end
end

# frozen_string_literal: true

module IntervalTree
  Node = Struct.new(:range, :left, :right, :max) do
    def overlaps?(other)
      range.min <= other.max && range.max >= other.min
    end
  end
end

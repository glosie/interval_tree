# frozen_string_literal: true

module IntervalTree
  Node = Struct.new(:range, :left, :right, :max, :height) do
    def overlaps?(other)
      if other.exclude_end?
        range.min < other.end && range.max >= other.begin
      else
        range.min <= other.end && range.max >= other.begin
      end
    end
  end
end

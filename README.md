# IntervalTree

An [augmented interval tree](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree)
for finding overlapping ranges in _O_(log n + k) time, backed by an AVL-balanced BST.

## Installation
Add this line to your application's Gemfile:
```ruby
gem 'interval_tree', github: 'glosie/interval_tree'
```

## Usage

### Building a tree

```ruby
tree = IntervalTree::Tree.new([1..2, 2..3, 3..5, 5..6])
```

If your intervals are already sorted by `[min, max]`, you can skip the sort:

```ruby
tree = IntervalTree::Tree.new(sorted_intervals, sorted: true)
```

### Searching

Search returns a lazy `Enumerable` of overlapping intervals:

```ruby
tree.search(3..4)
# => [2..3, 3..5]
```

Point queries work too — scalars are treated as single-point ranges:

```ruby
tree.search(3)
# => [2..3, 3..5]
```

Exclusive-end ranges are supported:

```ruby
tree.search(3...4)
# => [3..5]
```

Beginless and endless ranges work by normalizing nil bounds to infinity:

```ruby
tree.search(..3)   # everything overlapping up to 3
tree.search(5..)   # everything overlapping from 5 onward
```

### Dynamic insert and delete

The tree supports dynamic updates while maintaining AVL balance:

```ruby
tree.insert(4..7)
tree.delete(1..2)  # => 1..2 (returns the deleted range, or nil)
```

### Duck-type compatibility

Intervals can be any object that responds to `min`, `max`, and the comparison operators used by `Range`. For example, ActiveRecord models or custom structs work as stored intervals.

# IntervalTree

A partial implementation of an [augmented interval tree](https://en.wikipedia.org/wiki/Interval_tree#Augmented_tree)
for finding overlapping ranges in _O_(log n + k) time.

## Installation
Add this line you your application's Gemfile:
```ruby
gem 'interval_tree', github: 'glosie/interval_tree'
```

## Usage

```ruby
tree = IntervalTree::Tree.new([1..2, 2..3, 3..5, 5..6])
tree.search(3..4)
# => [2..3, 3..5]
```

## Todo
- support insertions and deletions

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'interval_tree'

require 'minitest/autorun'
require 'minitest/focus'
require 'minitest/reporters'

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(color: true)]

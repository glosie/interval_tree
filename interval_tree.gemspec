# frozen_string_literal: true

require_relative "lib/interval_tree/version"

Gem::Specification.new do |spec|
  spec.name = "interval_tree"
  spec.version = IntervalTree::VERSION
  spec.authors = ["Greg Losie"]
  spec.email = ["glosie@gmail.com"]

  spec.summary = "A Ruby interval tree implementation for efficient range overlap queries"
  spec.description = "An augmented interval tree data structure implementation in Ruby that enables " \
                     "efficient querying of overlapping intervals in O(log n + k) time."
  spec.homepage = "https://github.com/glosie/interval_tree"
  spec.license = "MIT"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/glosie/interval_tree",
    "bug_tracker_uri" => "https://github.com/glosie/interval_tree/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.required_ruby_version = ">= 2.7.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end

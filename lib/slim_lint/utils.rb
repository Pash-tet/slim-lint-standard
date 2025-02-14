# frozen_string_literal: true

module SlimLint
  # Miscellaneus collection of helper functions.
  module Utils
    module_function

    # Returns whether a glob pattern (or any of a list of patterns) matches the
    # specified file.
    #
    # This is defined here so our file globbing options are consistent
    # everywhere we perform globbing.
    #
    # @param glob [String, Array]
    # @param file [String]
    # @return [Boolean]
    def any_glob_matches?(globs_or_glob, file)
      path = File.expand_path(file)
      flags = File::FNM_PATHNAME | File::FNM_DOTMATCH
      Array(globs_or_glob).any? do |glob|
        File.fnmatch?(File.expand_path(glob), path, flags)
      end
    end

    # Find all consecutive items satisfying the given block of a minimum size,
    # yielding each group of consecutive items to the provided block.
    #
    # @param items [Array]
    # @param satisfies [Proc] function that takes an item and returns true/false
    # @param min_consecutive [Fixnum] minimum number of consecutive items before
    #   yielding the group
    # @yield Passes list of consecutive items all matching the criteria defined
    #   by the `satisfies` {Proc} to the provided block
    # @yieldparam group [Array] List of consecutive items
    # @yieldreturn [Boolean] block should return whether item matches criteria
    #   for inclusion
    def for_consecutive_items(items, satisfies, min_consecutive = 2)
      current_index = -1

      while (current_index += 1) < items.count
        next unless satisfies[items[current_index]]

        count = count_consecutive(items, current_index, &satisfies)
        next unless count >= min_consecutive

        # Yield the chunk of consecutive items
        yield items[current_index...(current_index + count)]

        current_index += count # Skip this patch of consecutive items to find more
      end
    end

    # Count the number of consecutive items satisfying the given {Proc}.
    #
    # @param items [Array]
    # @param offset [Fixnum] index to start searching from
    # @yield [item] Passes item to the provided block.
    # @yieldparam item [Object] Item to evaluate as matching criteria for
    #   inclusion
    # @yieldreturn [Boolean] whether to include the item
    # @return [Integer]
    def count_consecutive(items, offset = 0)
      count = 1
      count += 1 while (offset + count < items.count) && yield(items[offset + count])
      count
    end

    # Calls a block of code with a modified set of environment variables,
    # restoring them once the code has executed.
    #
    # @param env [Hash] environment variables to set
    def with_environment(env)
      old_env = {}
      env.each do |var, value|
        old_env[var] = ENV[var.to_s]
        ENV[var.to_s] = value
      end

      yield
    ensure
      old_env.each { |var, value| ENV[var.to_s] = value }
    end
  end
end

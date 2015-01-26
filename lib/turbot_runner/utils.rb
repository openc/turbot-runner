module TurbotRunner
  module Utils
    extend self

    def deep_copy(thing)
      Marshal.load(Marshal.dump(thing))
    end
  end
end

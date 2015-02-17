module TurbotRunner
  module Utils
    extend self

    def deep_copy(thing)
      Marshal.load(Marshal.dump(thing))
    end

    # This turns a hash of the form:
    #
    # {
    #   'a' => {
    #     'b' => {
    #       'c' => '123',
    #       'd' => '124',
    #     },
    #     'e' => {
    #       'f' => '156',
    #     }
    #   }
    # }
    #
    # into a hash of the form:
    #
    # {
    #   'a.b.c' => '123',
    #   'a.b.d' => '124',
    #   'a.e.f' => '156',
    # }
    def flatten(hash)
      pairs = []

      hash.each do |k, v|
        case v
        when Hash
          flatten(v).each do |k1, v1|
            pairs << ["#{k}.#{k1}", v1]
          end
        else
          pairs << [k, v]
        end
      end

      Hash[pairs]
    end
  end
end

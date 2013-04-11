module Mobj

  class ::Array
    alias includes? include?
    alias contains? include?

    def unempty?()
      !empty?
    end

    alias_method :notempty?, :unempty?

    def msum(initial = 0.0, op = :+, &block)
      map(&:to_f).inject(initial, block ? block : op)
    end

    def mavg(&block)
      msum(&block) / size
    end

    def values()
      self
    end

    def sequester(crush = true)
      if crush
        compact.size <= 1 ? compact.first : self
      else
        size <= 1 ? first : self
      end
    end

    def return_first(&block)
      returned = nil
      each { |item| break if (returned = block.call(item)) }
      returned
    end

    alias_method :earliest, :return_first
  end

end
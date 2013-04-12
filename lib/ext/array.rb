module Mobj

  class ::Array
    alias includes? include?
    alias contains? include?

    def unempty?()
      !empty?
    end

    alias_method :notempty?, :unempty?

    def msum(initial = 0.0, op = :+, &block)
      if block
        inject(initial) { |m, val| m.send(op, block[val]) }
      else
        map(&:to_f).inject(initial, op)
      end
    end

    def mavg(&block)
      msum(&block) / size
    end

    def mmid(&sorter)
      sorted = sort(&sorter)
      length.odd? ? sorted[length / 2] : (sorted[length/2 - 1] + sorted[length/2]).to_f / 2
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
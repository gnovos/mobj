module Mobj

  class ::Array
    alias_method :includes?, :include?
    alias_method :contains?, :include?

    def unempty?()
      !empty?
    end

    alias_method :notempty?, :unempty?

    def msum(initial = 0.0, op = :+, &block)
      if block
        inject(initial) { |m, val| m.send(op, block[val]) }
      else
        map(&:f!).inject(initial, op)
      end
    end

    def mavg(&block)
      msum(&block) / size
    end

    def mmid(&sorter)
      sorted = sort(&sorter)
      length.odd? ? sorted[length / 2].f! : (sorted[length/2 - 1].f! + sorted[length/2].f!).f! / 2
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

    def msym() map(&:sym) end

    def apply(to)
      map do |m|
        if m.is_a?(Symbol)
          to.send(m)
        else
          m.to_s.walk(to)
        end
      end
    end

    def meach(*args, &block)
      if block
        map { |item| instance_exec(item, *args, &block) }
      elsif args.size == 1
        map(&args.first.sym)
      else
        #args.each.with_object({}) do |action, o|
        #  o[action.sym] = map(&action.sym)
        #end
        method = args.shift
        map { |item| item.send(method, *args) }
      end
    end
  end

end
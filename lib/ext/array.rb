module Mobj

  class ::Array

    alias_method :includes?, :include?
    alias_method :contains?, :include?

    alias_method :mt?, :empty?
    def filled?() !mt? end
    alias_method :notempty?, :filled?
    alias_method :full?, :filled?
    alias_method :unempty?, :filled?

    def ny?(method, *args)
      any? { |o| o.send(method, *args) }
    end

    def no?(method, *args)
      none? { |o| o.send(method, *args) }
    end

    def ll?(method, *args)
      all? { |o| o.send(method, *args) }
    end

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

    def sequester!(crush = true)
      if crush
        compact.size <= 1 ? compact.first : self
      else
        size <= 1 ? first : self
      end
    end

    def realize!
      empty? ? nil : self
    end

    def return_first(&block)
      returned = nil
      each { |item| break if (returned = block.call(item)) }
      returned
    end

    alias_method :earliest, :return_first
    alias_method :first!, :return_first

    def msym() map(&:sym) end

    def apply(to)
      map do |m|
        if m.m?
          to.send(m)
        else
          m.s!.walk(to)
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

    def mall?(op, &block)
      if op
        all? { |item| item.send(op) }
      elsif block
        all? { |item| item.instance_exec(item, &block) }
      else
        all? { |item| item }
      end
    end

    def hmap(&block)
      each.with_object({}, &block)
    end
  end

end
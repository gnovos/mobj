module Mobj

  class ::FalseClass

    def zero?
      true
    end

    def tru?(_=nil, f=nil, &block)
      f
    end

    def fals?(val=nil, &block)
      if block
        block.call(val)
      else
        val
      end
    end

    def iff?(_=nil)
      nil
    end

    def iffn?(value = nil, &block)
      block ? instance_exec(value, &block) : value
    end

  end

end
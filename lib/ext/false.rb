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
    end

  end

end
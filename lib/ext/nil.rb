module Mobj

  class ::NilClass
    MOBJ_NULL_REGION_BEGIN = __LINE__

    def __mobj__caller()
      caller.find do |frame|
        (file, line) = frame.split(":")
        file != __FILE__ || !(MOBJ_NULL_REGION_BEGIN..MOBJ_NULL_REGION_END).cover?(line.to_i)
      end
    end

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
      self
    end

    def iffn?(value = nil, &block)
      block ? instance_exec(value, &block) : value
    end

    def null?(*)
      @@null ||= nil
      @@null && @@null == __mobj__caller
    end

    def null!(*)
      @@null = __mobj__caller
      self
    end

    def nil!(*)
      @@null = nil
      self
    end

    def method_missing(name, *args, &block)
      if null?
        self
      else
        nil!
        super
      end
    end

    alias_method :try?, :null!

    MOBJ_NULL_REGION_END = __LINE__

    def attempt(value=true)
      Forwarder.new do |name, *args, &block|
        if self.methods(true).include? name
          self.__send__(name, *args, &block)
        elsif value.is_a?(Proc)
          value.call([name] + args, &block)
        elsif value.is_a?(Hash) && value.ki?(name)
          value[name].when.is_a?(Proc).call(*args, &block)
        else
          value
        end
      end
    end
  end

end
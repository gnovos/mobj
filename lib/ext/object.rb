module Mobj

  class ::Object
    alias responds_to? respond_to?

    def rand?
      rand(1000000).odd?
    end

    def sym()
      if respond_to?(:to_sym)
        to_sym
      else
        to_s.to_sym
      end
    end

    def __mobj__root()
      __mobj__parent.nil? || __mobj__parent == self ? self : __mobj__parent.__mobj__root
    end

    def __mobj__reparent()
      values.each { |v| v.__mobj__parent(self); v.__mobj__reparent } if respond_to? :values
    end

    def __mobj__parent?()
      !@__mobj__parent.nil?
    end

    def __mobj__parent(rent = :"__mobj__parent")
      unless rent == :"__mobj__parent"
        @__mobj__parent = rent == self ? nil : rent
      end
      @__mobj__parent
    end

    def attempt(value=:root)
      Forwarder.new do |name, *args, &block|
        if self.methods(true).include? name ##//use respond to?
          self.__send__(name, *args, &block)
        elsif value.is_a?(Proc)
          value.call([name] + args, &block)
        elsif value.is_a?(Hash) && value.ki?(name)
          value[name].when.is_a?(Proc).call(*args, &block)
        else
          value == :root ? self : value
        end
      end
    end

    def try?(default=nil, &block)
      Forwarder.new do |name, *args, &fblock|
        if methods(true).include?(name)
          __send__(name, *args, &fblock)
        elsif is_a?(Hash) && ki?(name)
          self[name]
        end || (block ? instance_exec(*[*default], &block) : default) || nil.null!
      end
    end

    alias_method :ifnil, :try?

    def when
      Forwarder.new do |name, *args, &block|
        if methods.include?(name) && __send__(name, *args, &block)
          thn = Forwarder.new do |name, *args, &block|
            if name.sym == :then
              thn
            else
              ret = __send__(name, *args, &block)
              ret.define_singleton_method(:else) { Forwarder.new { ret } }
              ret
            end
          end
        else
          Forwarder.new do |name|
            if name.sym == :then
              els = Forwarder.new do |name|
                if name.sym == :else
                  Forwarder.new { |name, *args, &block| __send__(name, *args, &block) }
                else
                  els
                end
              end
            else
              self
            end
          end
        end
      end
    end

    alias_method :if?, :when
  end

end
module Mobj

  class ::Object

    def null!(*) self end
    def nil!(*) self end

    def wrap!(*args, &block)
      block ? instance_exec(*args, &block) : args.sequester!
    end

    alias_method :alter!, :wrap!
    alias_method :be!, :wrap!

    alias_method :with!, :tap

    def tru?(t=true, _=nil, &block) block ? instance_exec(t, &block) : t end
    def fals?(*) nil end

    def iff?(value = nil, &block) block ? instance_exec(value, &block) : value end
    def iffn?(_=nil) nil end

    def responds_to?(*any)
      any.flatten.select { |method| respond_to?(method) }.realize!
    end

    def responds_to_all?(*all)
      responds_to?(all) == all
    end

    def a?(*kls)
      kls.when.mt?.be!([Array]).any? { |k| is_a? k }
    end

    def p?() a? Proc end
    def m?() a? Symbol end
    def s?() a? String end
    def i?() a? Fixnum end
    def f?() a? Float end
    def n?() a? Fixnum, Float end

    def h?() a? Hash end
    def c?() a? Array, Hash end

    def x?() a? NilClass, FalseClass end

    def z0?() respond_to?(:zero?) ? zero? : f!.zero? end

    def un?()
      x? || (s? && s !~ /\S/) || (c? && mt?) || (n? && z0?)
    end

    def o?() !un? end

    def i!() to_s.scan(/[\d\.]+/).join.to_i end #xxx strip out junk?
    def f!() to_s.scan(/[\d\.]+/).join.to_f end
    def s!() to_s end
    def zeno!() z0? ? 1.0 : self end

    def u!(*args)
      if a?
        each { |i| i.u!(*args) }
      else
        if responds_to_all? :assign_attributes, :save
          args.select(&:h?).each do |arg|
            assign_attributes(arg)
          end
          save(validate:false)
        elsif responds_to? :update_attribute
          args.select(&:h?).each do |arg|
            arg.each do |k, v|
              update_attribute(k, v)
            end
          end
        end
      end
    end

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
      iam = self
      Forwarder.new do |name, *args, &block|
        if (iam.respond_to?(name) || iam.methods.include?(name)) && (got = iam.__send__(name, *args, &block))
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
          ret = Forwarder.new do |name, *args, &block|
            if name.sym == :then
              els = Forwarder.new do |name|
                if name.sym == :else
                  Forwarder.new { |name, *args, &block| __send__(name, *args, &block) }
                else
                  els
                end
              end
            else
              iam
            end
          end
        end
      end
    end

    alias_method :if?, :when

  end

end
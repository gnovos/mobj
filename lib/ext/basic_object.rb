module Mobj

  class ::BasicObject
    def class
      klass = class << self;
        self
      end
      klass.superclass
    end

    def null!(*)
      self
    end

    def nil!(*)
      self
    end

    def itself()
      self
    end

    def wrap(*args, &block)
      instance_exec(*args, &block)
    end

    alias_method :alter, :wrap

    def tru?(t=true, _=nil, &block)
      block ? instance_exec(t, &block) : t
    end

    def fals?(*)
      nil
    end

  end


end
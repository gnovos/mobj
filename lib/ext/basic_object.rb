module Mobj

  class ::BasicObject
    def class
      klass = class << self;
        self
      end
      klass.superclass
    end

    def itself() self end
    alias_method :self!, :itself

    def p!(method=:puts)
      send(method, self)
      self
    end

  end


end
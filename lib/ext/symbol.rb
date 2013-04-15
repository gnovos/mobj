module Mobj

  class ::Symbol
    def walk(obj)
      to_s.walk(obj)
    end

    def method_missing(name, *args, &block)
      str = to_s
      str.respond_to?(name) ? str.send(name, *args, &block) : super
    end
  end

end
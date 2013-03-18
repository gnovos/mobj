module Mobj

  class ::Symbol
    def walk(obj)
      to_s.walk(obj)
    end
  end

end
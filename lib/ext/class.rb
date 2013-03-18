module Mobj

  class ::Class
    def object_methods()
      (self.instance_methods(true) - Object.instance_methods(true)).sort
    end

    def class_methods()
      (self.singleton_methods(true) - Object.singleton_methods(true)).sort
    end

    def defined_methods()
      (class_methods | object_methods).sort
    end
  end

end
module Mobj

  class ::Proc
    def <=(arg) call(arg) end
    def <<(arg) call(arg) end
    def <(arg) call(arg) end
  end

end
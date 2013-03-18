module Mobj

  class ::Float
    def delimit(delim = ',')
      "#{to_i.delimit(delim)}.#{to_s.to_s[/\.(\d+)$/, 1]}"
    end
  end

end
module Mobj

  class ::Fixnum
    def delimit(delim = ',')
      to_s.split('').reverse.each_slice(3).to_a.map(&:join).join(delim).reverse
    end
  end

end
module Mobj

  module MatchEx
    def to_h
      Hash[names.map(&:sym).zip(captures)]
    end

    def method_missing(name, *args, &block)
      if name[-1] == '?' && names.includes?(name[0...-1])
        return to_h[name[0...-1].sym]
      elsif names.includes?(name.to_s)
        return to_h[name.sym]
      end
      super
    end
  end

  class ::MatchData
    include MatchEx
  end

end
module Mobj

  module HashEx

    def ki(name)
      name.to_s[/(.*?)[?!=]?$/, 1]
    end

    def ki?(name)
      [name.sym, name.to_s, ki(name).sym, ki(name).to_s].any? { |k| key?(k) }
    end

    def symvert(key_converter = :itself, value_converter = key_converter)
      each.with_object({}) do |(k, v), o|
        key = if key_converter.is_a?(Proc)
          key_converter.call(k, v)
        elsif k.respond_to?(key_converter.sym)
          k.__send__(key_converter.sym)
        else
          k
        end

        value = if value_converter.is_a?(Proc)
          value_converter.arity == 1 ? value_converter.call(v) : value_converter.call(k, v)
        elsif v.respond_to?(value_converter.sym)
          v.__send__(value_converter.sym)
        else
          v
        end

        o[key] = value
      end
    end

    def symvert!(key_converter = :itself, value_converter = key_converter)
      replace(symvert(key_converter, value_converter))
    end

    def method_missing(name, *args, &block)
      value = if name[-1] == '=' && args.size == 1
        key = name[0...-1].sym
        key = key.to_s if key?(key.to_s)
        self[key] = args.sequester
      elsif name[-1] == '?'
        key = name[0...-1].sym
        !!self[key, key.to_s]
      elsif name[-1] == '!'
        key = name[0...-1].sym
        val = self[key.sym] || self[key.to_s]
        if !val && (block || args.unempty?)
          self[key] = val = (block ? block.call(*args) : args.sequester)
        end
        super unless val
      else
        self[name.sym] || self[name.to_s]
      end
      value ||= args.sequester unless args.empty?

      return block ? block[value] : value
    end
  end

  class ::Hash
    include HashEx

    alias :mlookup :[]
    alias :mdef :default

    def [](*fkeys)
      fkeys.map { |key| mlookup(key) || fetch(key.sym) { fetch(key.to_s) { fetch(ki(key).sym) { fetch(ki(key).to_s) { mdef(key) } } } } }.sequester
    end
  end

end
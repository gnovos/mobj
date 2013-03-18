Dir["#{File.dirname(__FILE__)}/ext/*.rb"].each { |f| puts f; require f }

module Mobj

  class Forwarder < ::BasicObject
    attr_accessor :root, :handler
    def initialize(root = nil, &handler) @root, @handler = root, handler end
    def method_missing(name, *args, &block) handler.call(name, *args, &block) end
  end

  class Token
    def initialize(type, *args)
      @type, @path, @options = type.to_sym, nil, {}
      tokens = []
      args.each do |arg|
        if arg.is_a? Hash
          @options.merge!(arg)
        elsif arg.is_a? String
          tokens << arg.sym
        else
          tokens << arg
        end
      end
      @path = tokens.sequester
    end

    def to_s() "#{@type.to_s.upcase}(#@path#{ " => #@options" unless @options.empty?})" end

    def extract(obj, path)
      obj.__mobj__reparent
      if path == :* || obj.nil?
        obj
      elsif obj.is_a?(Array)
        if path[0] == '*' && obj.respond_to?(path[1..-1].sym)
          obj.__send__(path[1..-1].sym)
        else
          obj.map { |o| extract(o, path) }
        end
      elsif path.is_a?(Array)
        path.map { |pth| obj[pth.sym] }
      elsif path[0] == '*' && obj.respond_to?(path[1..-1].sym)
        obj.__send__(path[1..-1].sym)
      elsif obj.respond_to? :[]
        if obj.is_a?(Hash)
          obj[path.sym]
        else
          obj[path.to_s.to_i] if path.to_s =~ /^\d+$/
        end
      elsif obj.respond_to?(path.sym)
        obj.__send__(path.sym)
      else
        nil
      end
    end

    def find(obj, match)
      if obj.is_a?(Array)
        obj.map do |child|
          find(child, match)
        end
      elsif obj.respond_to?(:keys)
        found = obj.keys.each.with_object({}) { |key, fnd|
          m = key.to_s.match(match)
          fnd[key] = m if m
        }

        flat = found.values.flat_map(&:captures).empty?

        found.each.with_object(flat ? [] : {}) { |(key, m), map|
          if map.is_a?(Array)
            map << obj[key]
          else
            named = m.to_h.invert
            name = if named.empty?
              m.captures.empty? ? key : m.captures.sequester
            else
              named.find { |k, v| !k.nil? }.attempt(key).last
            end
            map[name] = obj[key]
          end
        }

      end
    end

    def walk(obj, root = obj)
      obj, root = Circle.wrap(obj), Circle.wrap(root)
      val = case @type
              when :literal
                @path.to_s
              when :path
                extract(obj, @path)
              when :regex
                find(obj, @path)
              when :up
                if obj.respond_to? :parent
                  obj.__mobj__parent || obj.__mobj__parent
                else
                  obj.__mobj__parent
                end
              when :any
                if obj.is_a?(Array)
                  obj.map { |o| walk(o, root) }
                else
                  @path.return_first { |token| token.walk(obj, root) }
                end
              when :all
                matches = @path.map { |token| token.walk(obj, root) }
                matches.compact.size == @path.size ? matches : nil
              when :each
                @path.map { |token| token.walk(obj, root) }
              when :lookup
                lookup = @path.walk(obj)
                if lookup.is_a?(Array)
                  lookup.flatten.map { |lu| lu.tokenize.walk(root) }.flatten(1)
                else
                  lookup.tokenize.walk(root)
                end
              when :inverse
                raise "not implemented yet. not sure how to implement yet, actually. please continue to hold. your call is important to us."
              when :root
                tree = [@path].flatten
                while (path = tree.shift)
                  obj = path.walk(obj)
                end
                obj.is_a?(Array) ? obj.flatten : obj
            end

      val = @options[:indexes] ? val.values_at(*@options[:indexes]) : val
      val
    end
  end

  class Circle
    def self.wrap(wrapped)
      return wrapped if wrapped.is_a?(CircleHash) || wrapped.is_a?(CircleRay)

      if wrapped.is_a?(Array)
        circle = CircleRay.new
        wrapped.each_with_index { |item, i| circle[i] = wrap(item) }
        circle
      elsif wrapped.is_a?(Hash)
        circle = CircleHash.new
        wrapped.each_pair { |key, val| circle[key] = wrap(val) }
        circle
      else
        wrapped
      end
    end
  end

  class CircleHash < Hash
    def *(&block)
      if block.nil?
        self
      else
        map = CircleHash.new
        self.each_pair do |key, val|
          map.merge!(block.call(key, val))
        end
        map
      end
    end

    def []=(*keys, val)
      val.__mobj__parent(self)
      keys.each { |key| store(key.sym, val) }
    end
  end

  class CircleRay < Array
    alias_method :*, :map

    alias_method :set, :[]=
    def []=(*keys, val)
      val.__mobj__parent(self)
      set(*keys, val)
    end

    alias_method :append, :<<
    def <<(*vals)
      vals.each do |val|
        val.__mobj__parent(self)
        self.append(val)
      end
      self
    end

    alias_method :lookup, :[]
    def [](*keys) keys.map { |key| self.lookup(key) }.sequester end
  end

end


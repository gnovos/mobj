module Mobj

  class ::BasicObject
    def sym() respond_to?(:to_sym) ? to_sym : to_s.to_sym end
    def mparent(rent = :mparent) @mparent = rent unless rent == :mparent; @mparent end
    def mroot() mparent.nil? ? self : mparent.mroot end
  end

  class ::Object
    alias responds_to? respond_to?
  end

  class ::Class
    def object_methods() (self.instance_methods - Object.instance_methods).sort end
    def class_methods() (self.singleton_methods - Object.singleton_methods).sort end
    def defined_methods() (class_methods | object_methods).sort end
  end

  class ::Array
    alias includes? include?
    alias contains? include?

    def sequester(lim = 1) compact.size <= lim ? compact.first : self end
    def return_first(&block)
      returned = nil
      each { |item| break if (returned = block.call(item)) }
      returned
    end
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
      if path == :*
        obj
      elsif obj.is_a?(Array)
        obj.map { |o| extract(o, path)}
      elsif path.is_a?(Array)
        path.map { |pth| obj[pth.sym] }
      else
        obj[path.sym]
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
                obj.keys.map { |key| key if key.match(@path) }.compact.map{|key| obj[key]}
              when :up
                if obj.respond_to? :parent
                  obj.mparent || obj.parent
                else
                  obj.mparent
                end
              when :any
                @path.return_first { |token| token.walk(obj, root) }
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
                raise "not implemented yet.  not sure how to implement yet, actually.  please continue to hold.  your call is important to us."
              when :root
                tree = [@path].flatten
                while (path = tree.shift)
                  obj = path.walk(obj)
                end
                obj.is_a?(Array) ? obj.flatten : obj
            end

      @options[:indexes] ? val.values_at(*@options[:indexes])  : val
    end
  end

  class ::String
    def ~@() "~#{self}" end

    def tokenize
      tokens = []
      scan(/\~([^\.]+)|\/(.*?)\/|\{\{(.*?)\}\}|(\^)|([^\.\[]+)(?:\[([\d\+\.,-]+)\])?/).each do |literal, regex, lookup, up, path, indexes|
        if literal
          tokens << Token.new(:literal, literal)
        elsif lookup
          tokens << Token.new(:lookup, lookup.tokenize)
        elsif regex
          tokens << Token.new(:regex, Regexp.new(regex))
        elsif up
          tokens << Token.new(:up)
        elsif path
          eachs = path.split(",")
          ors = path.split("|")
          ands = path.split("&")
          if eachs.size > 1
            tokens << Token.new(:each, eachs.map { |token| token.tokenize() })
          elsif ands.size > 1
            tokens << Token.new(:all, ands.map { |token| token.tokenize() })
          elsif ors.size > 1
            tokens << Token.new(:any, ors.map { |token| token.tokenize() })
          end

          unless ands.size + ors.size + eachs.size > 3
            options = {}
            options[:indexes] = indexes.scan(/(\d+)(?:(?:\.\.(\.)?|-?)(-?\d+|\+))?/).map do |start, exc, len|
              len.nil? ? start.to_i : (Range.new(start.to_i, (len == "+" ? -1 : len.to_i), !exc.nil?))
            end if indexes

            if path[0] == '!'
              tokens << Token.new(:inverse, Token.new(:path, path[1..-1].sym, options))
            else
              tokens << Token.new(:path, path.sym, options)
            end
          end
        end
      end
      tokens.size == 1 ? tokens.first : Token.new(:root, tokens)
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
      val.mparent(self)
      keys.each { |key| store(key.sym, val) }
    end

    alias_method :lookup, :[]
    def [](*keys) keys.map { |key| self.lookup(key.sym) }.sequester end

    def method_missing(name, *args, &block) self.has_key?(name) ? self[name] : super(name, *args, &block) end
  end

  class CircleRay < Array
    alias_method :*, :map

    alias_method :set, :[]=
    def []=(*keys, val)
      val.mparent(self)
      set(*keys, val)
    end

    alias_method :append, :<<
    def <<(*vals)
      vals.each do |val|
        val.mparent(self)
        self.append(val)
      end
      self
    end

    alias_method :lookup, :[]
    def [](*keys)
      keys.map do |key|
        self.lookup(key)
      end.sequester
    end
  end

end

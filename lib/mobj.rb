module Mobj

  class ::BasicObject
    def class
      klass = class << self; self end
      klass.superclass
    end
    def null!() self end
    def nil!() self end
    def itself() self end
    def alter(*args, &block) block[*[self, *args]] || self; end
    alias_method :o!, :alter

  end

  class ::Fixnum
    def delimit(delim = ',')
      to_s.split('').reverse.each_slice(3).to_a.map(&:join).join(delim).reverse
    end
  end

  class ::Float
    def delimit(delim = ',')
      "#{to_i.delimit(delim)}.#{to_s.to_s[/\.(\d+)$/, 1]}"
    end
  end

  class Forwarder < ::BasicObject
    attr_accessor :root, :handler
    def initialize(root = nil, &handler) @root, @handler = root, handler end
    def method_missing(name, *args, &block) handler.call(name, *args, &block) end
  end

  class ::Object
    alias responds_to? respond_to?
    def sym() respond_to?(:to_sym) ? to_sym : to_s.to_sym end
    def __mobj__root() __mobj__parent.nil? || __mobj__parent == self ? self : __mobj__parent.__mobj__root end
    def __mobj__reparent() values.each { |v| v.__mobj__parent(self); v.__mobj__reparent } if respond_to? :values end
    def __mobj__parent?() !@__mobj__parent.nil? end
    def __mobj__parent(rent = :"__mobj__parent")
      unless rent == :"__mobj__parent"
        @__mobj__parent = rent == self ? nil : rent
      end
      @__mobj__parent
    end
    def attempt(value=:root)
      Forwarder.new do |name, *args, &block|
        if self.methods(true).include? name ##//use respond to?
          self.__send__(name, *args, &block)
        elsif value.is_a?(Proc)
          value.call([name] + args, &block)
        elsif value.is_a?(Hash) && value.ki?(name)
          value[name].when.is_a?(Proc).call(*args, &block)
        else
          value == :root ? self : value
        end
      end
    end

    def try?(default=nil)
      Forwarder.new do |name, *args, &block|
        if methods(true).include?(name)
          __send__(name, *args, &block)
        elsif is_a?(Hash) && ki?(name)
          self[name]
        end || default || nil.null!
      end
    end

    alias_method :ifnil, :try?

    def when
      Forwarder.new do |name, *args, &block|
        if methods.include?(name) && __send__(name, *args, &block)
          thn = Forwarder.new do |name, *args, &block|
            if name.sym == :then
              thn
            else
              ret = __send__(name, *args, &block)
              ret.define_singleton_method(:else) { Forwarder.new { ret } }
              ret
            end
          end
        else
          Forwarder.new do |name|
            if name.sym == :then
              els = Forwarder.new do |name|
                if name.sym == :else
                  Forwarder.new { |name, *args, &block| __send__(name, *args, &block) }
                else
                  els
                end
              end
            else
              self
            end
          end
        end
      end
    end
    alias_method :if?, :when
  end

  class ::NilClass
    MOBJ_NULL_REGION_BEGIN = __LINE__
    def __mobj__caller()
      caller.find do |frame|
        (file, line) = frame.split(":")
        file != __FILE__ || !(MOBJ_NULL_REGION_BEGIN..MOBJ_NULL_REGION_END).cover?(line.to_i)
      end
    end
    def null?()
      @@null ||= nil
      @@null && @@null == __mobj__caller
    end
    def null!()
      @@null = __mobj__caller
      self
    end
    def nil!
      @@null = nil
      self
    end
    def method_missing(name, *args, &block)
      if null?
        self
      else
        nil!
        super
      end
    end
    alias_method :try?, :null!

    MOBJ_NULL_REGION_END = __LINE__

    def attempt(value=true)
      Forwarder.new do |name, *args, &block|
        if self.methods(true).include? name
          self.__send__(name, *args, &block)
        elsif value.is_a?(Proc)
          value.call([name] + args, &block)
        elsif value.is_a?(Hash) && value.ki?(name)
          value[name].when.is_a?(Proc).call(*args, &block)
        else
          value
        end
      end
    end
  end

  class ::Class
    def object_methods() (self.instance_methods(true) - Object.instance_methods(true)).sort end
    def class_methods() (self.singleton_methods(true) - Object.singleton_methods(true)).sort end
    def defined_methods() (class_methods | object_methods).sort end
  end

  class ::Array
    alias includes? include?
    alias contains? include?

    def unempty?() !empty? end
    alias_method :notempty?, :unempty?

    def msum(initial = 0.0, op = :+, &block)
      map(&:to_f).inject(initial, block ? block : op)
    end

    def mavg(&block)
       msum(&block) / size
    end

    def values() self end
    def sequester(crush = true)
      if crush
        compact.size <= 1 ? compact.first : self
      else
        size <= 1 ? first : self
      end
    end
    def return_first(&block)
      returned = nil
      each { |item| break if (returned = block.call(item)) }
      returned
    end
  end

  module HashEx

    def ki(name)
      name.to_s[/(.*?)[?!=]?$/, 1]
    end

    def ki?(name)
      [name.sym, name.to_s, ki(name).sym, ki(name).to_s].any?{ |k| key?(k) }
    end

    def symvert(key_converter = :itself, value_converter = key_converter)
      each.with_object({}) do |(k,v),o|
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
      fkeys.map { |key| mlookup(key) || fetch(key.sym) { fetch(key.to_s) { fetch(ki(key).sym) { fetch(ki(key).to_s) { mdef(key) }}}}}.sequester
    end
  end

  module MatchEx
    def to_hash
      Hash[ names.map(&:sym).zip( captures ) ]
    end

    def method_missing(name, *args, &block)
      if name[-1] == '?' && names.includes?(name[0...-1])
        return to_hash[name[0...-1].sym]
      elsif names.includes?(name.to_s)
        return to_hash[name.sym]
      end
      super
    end
  end

  class ::MatchData
    include MatchEx
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
            named = m.to_hash.invert
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

  class ::Symbol
    def walk(obj) to_s.walk(obj) end
  end

  class ::String

    def matches(regexp)
      start = 0
      matches = []
      while (match = match(regexp, start))
        start = match.end(0)
        matches << match
        yield match if block_given?
      end
      matches
    end

    def walk(obj) tokenize.walk(obj) end

    def tokenize
      tokens = []

      lit = /\~(?<literal>[^\.]+)/
      regex = /\/(?<regex>.*?(?<!\\))\//
      lookup = /\{\{(?<lookup>.*?)\}\}/
      up = /(?<up>\^)/
      path = /(?<path>[^\.\[]+)/
      indexes = /(?<indexes>[\d\+\.,\s-]+)/

      matcher = /#{lit}|#{regex}|#{lookup}|#{up}|#{path}(?:\[#{indexes}\])?/

      matches(matcher) do |match|
        if match.literal?
          tokens << Token.new(:literal, match.literal)
        elsif match.lookup?
          tokens << Token.new(:lookup, match.lookup.tokenize)
        elsif match.regex?
          tokens << Token.new(:regex, Regexp.new(match.regex))
        elsif match.up?
          tokens << Token.new(:up)
        elsif match.path?
          eachs = match.path.split(/\s*,\s*/)
          ors = match.path.split(/\s*\|\s*/)
          ands = match.path.split(/\s*\&\s*/)
          if eachs.size > 1
            tokens << Token.new(:each, eachs.map { |token| token.tokenize() })
          elsif ands.size > 1
            tokens << Token.new(:all, ands.map { |token| token.tokenize() })
          elsif ors.size > 1
            tokens << Token.new(:any, ors.map { |token| token.tokenize() })
          end

          unless ands.size + ors.size + eachs.size > 3
            options = {}
            index_matcher = /\s*(?<low>\d+)\s*(?:(?:\.\s*\.\s*(?<ex>\.)?\s*|-?)\s*(?<high>-?\d+|\+))?\s*/

            options[:indexes] = match.indexes.matches(index_matcher).map do |index|
              if index.high?
                Range.new(index.low.to_i, (index.high == "+" ? -1 : index.high.to_i), index.ex?)
              else
                index.low.to_i
              end
            end if match.indexes?

            if match.path[0] == '!'
              tokens << Token.new(:inverse, Token.new(:path, match.path[1..-1].sym, options))
            else
              tokens << Token.new(:path, match.path.sym, options)
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


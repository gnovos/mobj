module Mobj


  #magic init
  #class Object
  #  alias_method :orig_method_missing, :method_missing
  #
  #  def method_missing(m, *a, &b)
  #    klass = begin
  #      (self.is_a?(Module) ? self : self.class).const_get(m)
  #    rescue NameError
  #    end
  #
  #    return klass.send(:parens, *a, &b)  if klass.respond_to? :parens
  #    orig_method_missing m, *a, &b
  #  end
  #end

  #class Object
  #  alias_method :orig_method_missing, :method_missing
  #
  #  def method_missing(m, *a, &b)
  #    begin
  #      l = eval(m.to_s, binding_n(1))
  #    rescue NameError
  #    else
  #      return l.call(*a)  if l.respond_to? :call
  #    end
  #    orig_method_missing m, *a, &b
  #  end
  #end
  #
  #def call_a_lambda_with_parenths(val)
  #  l = lambda {|v| p v }
  #  l(val)
  #end
  #
  #call_a_lambda_with_parenths(6)

  class ::BasicObject
    def class
      klass = class << self; self end
      klass.superclass
    end
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
    def s() respond_to?(:to_s) ? to_s : inspect end
    def str() respond_to?(:to_str) ? to_str : to_s end
    def mroot() mparent.nil? || mparent == self ? self : mparent.mroot end
    def reparent() values.each { |v| v.mparent(self); v.reparent } if respond_to? :values end
    def mparent(rent = :mparent)
      unless rent == :mparent
        @mparent = rent == self ? nil : rent
      end
      @mparent
    end
    def attempt(value=:root)
      Forwarder.new do |name, *args, &block|
        if self.methods(true).include? name
          self.__send__(name, *args, &block)
        elsif value.is_a?(Proc)
          value.call([name] + args, &block)
        elsif value.is_a?(Hash) && value.key?(name)
          value[name].when.is_a?(Proc).call(*args, &block)
        else
          value == :root ? self : value
        end
      end
    end
    alias_method :try?, :attempt
    alias_method :do?, :attempt
    alias_method :does?, :attempt
    alias_method :if!, :attempt

    def when
      Forwarder.new do |name, *args, &block|
        if self.methods.include?(name) && self.__send__(name, *args, &block)
          thn = Forwarder.new do |name, *args, &block|
            if name.sym == :then
              thn
            else
              ret = self.__send__(name, *args, &block)
              ret.define_singleton_method(:else) { Forwarder.new { ret } }
              ret
            end
          end
        else
          Forwarder.new do |name|
            if name.sym == :then
              els = Forwarder.new do |name|
                if name.sym == :else
                  Forwarder.new { |name, *args, &block| self.__send__(name, *args, &block) }
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
    def attempt(value=true)
      Forwarder.new do |name, *args, &block|
        if self.methods(true).include? name
          self.__send__(name, *args, &block)
        elsif value.is_a?(Proc)
          value.call([name] + args, &block)
        elsif value.is_a?(Hash) && value.key?(name)
          value[name].when.is_a?(Proc).call(*args, &block)
        else
          value
        end
      end
    end
    alias_method :try?, :attempt
    alias_method :do?, :attempt
    alias_method :does?, :attempt
    alias_method :if!, :attempt
  end

  class ::Class
    def object_methods() (self.instance_methods(true) - Object.instance_methods(true)).sort end
    def class_methods() (self.singleton_methods(true) - Object.singleton_methods(true)).sort end
    def defined_methods() (class_methods | object_methods).sort end
  end

  class ::Array
    alias includes? include?
    alias contains? include?

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
    def method_missing(name, *args, &block)
      if name[-1] == '=' && args.size == 1
        key = name[0...-1].sym
        key = key.s if key?(key.s)
        return self[key] = args.sequester
      elsif name[-1] == '?'
        key = name[0...-1].sym
        return !!self[key, key.to_s]
      elsif key?(name.sym) || key?(name.to_s)
        return self[name.sym] || self[name.to_s]
      end
      super
    end
  end

  class ::Hash
    include HashEx

    alias :mlookup :[]
    alias :mdef :default
    def [](*fkeys)
      fkeys.map { |key| mlookup(key) || fetch(key.sym) { fetch(key.to_s) { mdef(key) }  } }.sequester
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
      obj.reparent
      if path == :* || obj.nil?
        obj
      elsif obj.is_a?(Array)
        obj.map { |o| extract(o, path) }
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
                obj.keys.map { |key| key if key.match(@path) }.compact.map{|key| obj[key] }
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

  class ::String
    def ~@() "~#{self}" end
    def -@() "^.#{self}" end

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
    def [](*keys) keys.map { |key| self.lookup(key) }.sequester end
  end
end


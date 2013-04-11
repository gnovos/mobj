require 'mobj'

module Mobj

  ANSI = {
      colors: {
          k: 0, #:black,
          r: 1, #:red,
          g: 2, #:green,
          y: 3, #:yellow,
          b: 4, #:blue,
          m: 5, #:magenta,
          c: 6, #:cyan,
          w: 7 #:white,
      },
      options: {
          #:'*' => 90, #:bright,
          #:'^' => 90, #:bright,
          :'!' => 1, #:bold,
          B: 1, #:bold,
          f: 2, #:faint,
          i: 3, #:italics,
          u: 4, #:underline,
          _: 4, #:underline,
          x: 5, #:blink,
          F: 6, #:blink_fast,
          U: 21 #:double_underline
      }
  }

  class ::String

    def cfmt
      colors = ANSI.colors.keys.join
      opts   = ANSI.options.keys.join
      formatted = self
      matches(/\{(?<color>[#{colors}]?)(?<opts>[#{opts}*^]*)\|(?<str>.*?)\}/).each do |m|
        opts = m.opts.split(//).map(&:sym)
        bright = (opts.delete(:'*') || opts.delete(:'^')) ? 90 : 30
        codes = [(ANSI.colors[m.color].to_i + bright)] + ANSI.options.values_at(*opts).compact
        formatted = formatted.sub(m[0], "\033[#{codes.join(';')}m#{m.str}\033[m")
      end

      formatted
    end
    alias_method :c!, :cfmt

    def <(*args)
      self.cfmt.%(*args)
    end

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

    def walk(obj)
      tokenize.walk(obj)
    end

    def tokenize
      tokens = []

      lit    = /\~(?<literal>[^\.]+)/
      regex  = /\/(?<regex>.*?(?<!\\))\//
      lookup = /\{\{(?<lookup>.*?)\}\}/
      up     = /(?<up>\^)/
      path   = /(?<path>[^\.\[]+)/
      indexes = /(?<indexes>[\d\+\.,\s-]+)/

      matcher = /#{lit}|#{regex}|#{lookup}|#{up}|#{path}(?:\[#{indexes}\])?/

      matches(matcher) do |match|
        if match.literal?
          tokens << Mobj::Token.new(:literal, match.literal)
        elsif match.lookup?
          tokens << Mobj::Token.new(:lookup, match.lookup.tokenize)
        elsif match.regex?
          tokens << Mobj::Token.new(:regex, Regexp.new(match.regex))
        elsif match.up?
          tokens << Mobj::Token.new(:up)
        elsif match.path?
          eachs = match.path.split(/\s*,\s*/)
          ors  = match.path.split(/\s*\|\s*/)
          ands = match.path.split(/\s*\&\s*/)
          if eachs.size > 1
            tokens << Mobj::Token.new(:each, eachs.map { |token| token.tokenize() })
          elsif ands.size > 1
            tokens << Mobj::Token.new(:all, ands.map { |token| token.tokenize() })
          elsif ors.size > 1
            tokens << Mobj::Token.new(:any, ors.map { |token| token.tokenize() })
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
              tokens << Mobj::Token.new(:inverse, Token.new(:path, match.path[1..-1].sym, options))
            else
              tokens << Mobj::Token.new(:path, match.path.sym, options)
            end
          end
        end
      end

      tokens.size == 1 ? tokens.first : Mobj::Token.new(:root, tokens)
    end
  end

end
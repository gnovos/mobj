require 'mobj'

module Mobj

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
          tokens << Token.new(:literal, match.literal)
        elsif match.lookup?
          tokens << Token.new(:lookup, match.lookup.tokenize)
        elsif match.regex?
          tokens << Token.new(:regex, Regexp.new(match.regex))
        elsif match.up?
          tokens << Token.new(:up)
        elsif match.path?
          eachs = match.path.split(/\s*,\s*/)
          ors  = match.path.split(/\s*\|\s*/)
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

end
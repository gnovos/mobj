require 'spec_helper'

describe Mobj do

  describe BasicObject do
    it "Can symbilize stuff" do
      nil.sym.should == :""
      "foo".sym.should == :foo
      "".sym.should == :""
      1.sym.should == :"1"
    end

    it "can have parents and find it's root" do
      a = "a"
      b = "b"
      c = "c"

      c.mparent(b)
      b.mparent(a)

      a.mroot.should == a
      b.mroot.should == a
      c.mroot.should == a

      c.mparent.should == b
      b.mparent.should == a
    end
  end

  describe Class do
    it "should have helper methods to get it's methods" do
      String.object_methods.should == [:%, :*, :+, :<, :<<, :<=, :>, :>=, :[], :[]=, :ascii_only?, :between?, :bytes, :bytesize, :byteslice, :capitalize, :capitalize!, :casecmp, :center, :chars, :chomp, :chomp!, :chop, :chop!, :chr, :clear, :codepoints, :concat, :count, :crypt, :delete, :delete!, :downcase, :downcase!, :dump, :each_byte, :each_char, :each_codepoint, :each_line, :empty?, :encode, :encode!, :encoding, :end_with?, :force_encoding, :getbyte, :gsub, :gsub!, :hex, :include?, :index, :insert, :intern, :length, :lines, :ljust, :lstrip, :lstrip!, :match, :next, :next!, :oct, :ord, :partition, :prepend, :replace, :reverse, :reverse!, :rindex, :rjust, :rpartition, :rstrip, :rstrip!, :scan, :setbyte, :shellescape, :shellsplit, :size, :slice, :slice!, :split, :squeeze, :squeeze!, :start_with?, :strip, :strip!, :sub, :sub!, :succ, :succ!, :sum, :swapcase, :swapcase!, :to_c, :to_f, :to_i, :to_r, :to_str, :to_sym, :tokenize, :tr, :tr!, :tr_s, :tr_s!, :unpack, :upcase, :upcase!, :upto, :valid_encoding?, :~]
      String.class_methods.should == [:try_convert]
      String.defined_methods.should == [:%, :*, :+, :<, :<<, :<=, :>, :>=, :[], :[]=, :ascii_only?, :between?, :bytes, :bytesize, :byteslice, :capitalize, :capitalize!, :casecmp, :center, :chars, :chomp, :chomp!, :chop, :chop!, :chr, :clear, :codepoints, :concat, :count, :crypt, :delete, :delete!, :downcase, :downcase!, :dump, :each_byte, :each_char, :each_codepoint, :each_line, :empty?, :encode, :encode!, :encoding, :end_with?, :force_encoding, :getbyte, :gsub, :gsub!, :hex, :include?, :index, :insert, :intern, :length, :lines, :ljust, :lstrip, :lstrip!, :match, :next, :next!, :oct, :ord, :partition, :prepend, :replace, :reverse, :reverse!, :rindex, :rjust, :rpartition, :rstrip, :rstrip!, :scan, :setbyte, :shellescape, :shellsplit, :size, :slice, :slice!, :split, :squeeze, :squeeze!, :start_with?, :strip, :strip!, :sub, :sub!, :succ, :succ!, :sum, :swapcase, :swapcase!, :to_c, :to_f, :to_i, :to_r, :to_str, :to_sym, :tokenize, :tr, :tr!, :tr_s, :tr_s!, :try_convert, :unpack, :upcase, :upcase!, :upto, :valid_encoding?, :~]
    end
  end

  describe Array do
    it "can select the first block that return non-nil" do
      count = 0
      [1,2,3,4,5].return_first { |i| count += 1; i == 3 ? "found" : nil }.should == "found"
      count.should == 3
    end
    
    it "can sequester into a single result if there are fewer than the limit of items" do      
      [1].sequester.should == 1
      [1,2].sequester.should == [1, 2]
      [1,2].sequester(2).should == 1
      [1,2,3].sequester(2).should == [1, 2, 3]
    end
  end

  describe Mobj::Moken do
    it "can walk a tree" do
      obj = {
          a: [ "b", "c", "d"],
          b: [ { c: { d: "foundA" } }, { c: { d: "foundB" } } ],
          c: [ [[{d:'f0'},{d:'f1'}], [{d:'f2'},{d:'f3'}]], [[{d:'f4'},{d:'f5'}], [{d:'f6'},{d:'f7'}]] ],
          d: [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
          e: nil,
          f: nil,
          g: "found by any",
          h: "not any",
          foo_a: "regex0",
          foo_b: "regex1",
          foo_ccccc: "regex2",
          i: { j: [ {k:"found0"}, {k:"found1"} ] },
          l: { m: [ {n:"found2"}, {n:"found3"} ] },
          lookval: { o: [ "i.j.k", "l.m.n" ] }
      }

      Mobj::Moken.new(:path, "a").walk(obj).should == obj[:a]
      Mobj::Moken.new(:root,
                      Mobj::Moken.new(:path, :b),
                      Mobj::Moken.new(:path, :c),
                      Mobj::Moken.new(:path, :d)).walk(obj).should == [ "foundA", "foundB"]
      Mobj::Moken.new(:root,
                      Mobj::Moken.new(:path, :c),
                      Mobj::Moken.new(:path, :d)).walk(obj).should == [ 'f0','f1','f2','f3','f4','f5','f6', 'f7' ]
      Mobj::Moken.new(:root,
                      Mobj::Moken.new(:path, :c)).walk(obj).should == [ {d:'f0'}, {d:'f1'}, {d:'f2'}, {d:'f3'}, {d:'f4'}, {d:'f5'}, {d:'f6'}, {d:'f7'} ]
      Mobj::Moken.new(:path, :d, indexes: [1, 2..4, 5...7, 8..-1]).walk(obj).should == [ 1, 2, 3, 4, 5, 6, 8, 9 ]
      Mobj::Moken.new(:literal, :foo).walk(obj).should == "foo"
      Mobj::Moken.new(:any,
                      Mobj::Moken.new(:path, :e),
                      Mobj::Moken.new(:path, :f),
                      Mobj::Moken.new(:path, :g),
                      Mobj::Moken.new(:path, :h)).walk(obj).should == "found by any"
      Mobj::Moken.new(:each,
                      Mobj::Moken.new(:path, :e),
                      Mobj::Moken.new(:path, :f),
                      Mobj::Moken.new(:path, :g),
                      Mobj::Moken.new(:path, :h)).walk(obj).should == [nil, nil, "found by any", "not any"]
      Mobj::Moken.new(:all,
                      Mobj::Moken.new(:path, :e),
                      Mobj::Moken.new(:path, :f),
                      Mobj::Moken.new(:path, :g),
                      Mobj::Moken.new(:path, :h)).walk(obj).should == nil
      Mobj::Moken.new(:all,
                      Mobj::Moken.new(:path, :g),
                      Mobj::Moken.new(:path, :h)).walk(obj).should == [ "found by any", "not any" ]
      Mobj::Moken.new(:regex, /foo_.*/).walk(obj).should == [ "regex0", "regex1", "regex2" ]
      Mobj::Moken.new(:lookup, Mobj::Moken.new(:root, Mobj::Moken.new(:path, :lookval), Mobj::Moken.new(:path, :o))).walk(obj).should == [ "found0", "found1", "found2", "found3" ]
    end
  end

  describe String do
    it "can convery to literal using unary ~ operator" do
      str = ~"str"
      str.should == "~str"
    end

    it "can parse itself into path tokens" do
      path = "a.b1|b2|~lit.c[0,0-0,0..0,0...0,0+]./de/.f&g.{{h}}.j,k,l./(m).|&\\{\\[/.n.!o.{{p.q}}.r&s|t,u"

      path.tokenize.to_s.should ==
          Mobj::Moken.new(:root,
                          Mobj::Moken.new(:path, :a),
                          Mobj::Moken.new(:any, Mobj::Moken.new(:path, "b1"), Mobj::Moken.new(:path, "b2"), Mobj::Moken.new(:literal, "lit")),
                          Mobj::Moken.new(:path, "c", :indexes => [0, 0..0, 0..0, 0...0, 0..-1]),
                          Mobj::Moken.new(:regex, /de/),
                          Mobj::Moken.new(:all, Mobj::Moken.new(:path, "f"), Mobj::Moken.new(:path, "g")),
                          Mobj::Moken.new(:lookup, Mobj::Moken.new(:path, "h")),
                          Mobj::Moken.new(:each, Mobj::Moken.new(:path, "j"), Mobj::Moken.new(:path, "k"), Mobj::Moken.new(:path, "l")),
                          Mobj::Moken.new(:regex, /(m).|&\{\[/),
                          Mobj::Moken.new(:path, "n"),
                          Mobj::Moken.new(:inverse, Mobj::Moken.new(:path, "o")),
                          Mobj::Moken.new(:lookup, Mobj::Moken.new(:root, Mobj::Moken.new(:path, "p"), Mobj::Moken.new(:path, "q"))),
                          Mobj::Moken.new(:each, Mobj::Moken.new(:all, Mobj::Moken.new(:path, "r"),
                                                              Mobj::Moken.new(:any, Mobj::Moken.new(:path, "s"), Mobj::Moken.new(:path, "t"))),
                                        Mobj::Moken.new(:path, "u")),
          ).to_s
    end
  end

  describe Mobj::Circle do
    it "can sort of be either an array or a hash" do
      circle = Mobj::Circle.new
      circle['foo'] = 'bar'
      circle[0] = "hello"
      circle << "world"
      circle[5..7] = "5-7 vals"

      circle.to_s.should == "{:foo=>\"bar\", :\"0\"=>\"hello\", :\"1\"=>\"world\", :\"5\"=>\"5-7 vals\", :\"6\"=>\"5-7 vals\", :\"7\"=>\"5-7 vals\"}"
      circle.foo.should == "bar"
      circle['foo'].should == "bar"
      circle[:foo].should == "bar"
      circle[0].should == "hello"

    end

    it "can wrap nested arrays and hashes" do
      noncirc = { foo: [ 1, 2, 3, 4], bar: { baz: 'hello', biz: 'world', whiz: [ { innera: 1 }, { innerb: 1 }, { innerc: 1 } ]}}
      circle = Mobj::Circle.wrap(noncirc)
      circle.to_s.should == "{:foo=>{:\"0\"=>1, :\"1\"=>2, :\"2\"=>3, :\"3\"=>4}, :bar=>{:baz=>\"hello\", :biz=>\"world\", :whiz=>{:\"0\"=>{:innera=>1}, :\"1\"=>{:innerb=>1}, :\"2\"=>{:innerc=>1}}}}"
    end

  end


end

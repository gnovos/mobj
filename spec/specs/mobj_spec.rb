require 'spec_helper'

describe Mobj do

  describe ::Float do
    it "can delimit" do
      1234567890.234.delimit.should == "1,234,567,890.234"
      1.5.delimit.should == "1.5"
      123.1234.delimit.should == "123.1234"
    end
  end

  describe ::Fixnum do
    it "can delimit" do
      1234567890.delimit.should == "1,234,567,890"
      1.delimit.should == "1"
      123.delimit.should == "123"
    end
  end

  describe NilClass do
    it "can chain methods when in null mode but still be nil/falsy" do
      nil.null?.should be_false
      nil.null!.null?.should be_true
      nil.null?.should be_false
      nil.null!.nil!.null?.should be_false

      nil.null!.foo.bar.baz.should be_nil
      expect { nil.foo }.to raise_exception

      o = "foo:bar"
      o.null!.split(':').should == ["foo", "bar"]

      o = nil
      o.null!.split(':').should be_nil

      expect { o.null!.foo.bar.nil! || o.foo }.to raise_exception

    end

    it "can attempt otherwise provide values" do
      nil.inspect.should == "nil"
      nil.attempt.foo.should be_true
      nil.attempt("right").foo.should == "right"
      nil.attempt({ foo: "right", bar: "wrong" }).foo.should == "right"
      nil.attempt({ foo: proc { |var| "right #{var}" }, bar: "wrong" }).foo("selection").should == "right selection"
      nil.attempt({ foo: "right", bar: "right" }).baz.should == { foo: "right", bar: "right" }
    end
  end

  describe Object do

    it "can be altered and replaced" do
      o = { foo: 'foo', bar: 'bar' }
      o.alter { self.foo }.should == 'foo'
      o.alter {  }.should be_nil
      o.alter('val'){ |v| "#{v}=#{self.foo}" }.should == 'val=foo'
    end


    it "can when" do
      o = Object.new
      def o.foo_true() true end
      def o.foo_false() false end
      def o.bar() "bar" end
      def o.baz() "baz" end
      o.when.foo_true.then.bar.else.baz.should == "bar"
      o.when.foo_false.then.bar.else.baz.should == "baz"
      o.when.foo.then.bar.else.baz.should == "baz"

      o.when.foo_true.bar.should == "bar"
      o.when.foo_false.bar.should == o

      o.if?.foo_true.then.bar.else.baz.should == "bar"
    end

    it "can try?" do
      "1.3".try?.to_f.should == 1.3
      "1.3".try?.foo.should be_false

      "1.3".try?.to_f.to_s.split('').join("-").should == "1-.-3"
      var = nil
      var.try?.foo.should be_nil
      var.try?.foo.split('').join("-").should be_nil

      hash = { foo: { bar:'baz' } }

      hash.foo.try?.bar.should == 'baz'
      hash.foo.try?.baz.should be_false
      hash.foo.try?('def').baz.should == 'def'
      hash.foo.try? { self.bar }.biz.should == 'baz'

    end

    it "can attempt or otherwise provide values" do

      "1.3".attempt.to_z.should == "1.3"
      "1.3".attempt.to_f.should == 1.3

      "some string".attempt.to_s.should == "some string"
      "some string".attempt.to_z.should == "some string"

      "some string".attempt("value").to_s.should == "some string"
      "nil".attempt("other value").unknown_method.should == "other value"

      "some string".attempt("value").foo.should == "value"
      "some string".attempt({ foo: "right", bar: "wrong" }).foo.should == "right"
      "some string".attempt({ foo: proc { |var| "right #{var}" }, bar: "wrong" }).foo("selection").should == "right selection"
      "some string".attempt({ foo: "right", bar: "right" }).baz.should == { foo: "right", bar: "right" }

    end

    it "Can symbolize and s stuff" do
      nil.sym.should == :""
      "foo".sym.should == :foo
      "".sym.should == :""
      1.sym.should == :"1"
    end

    it "can have parents and find it's root" do
      a = "a"
      b = "b"
      c = "c"

      c.__mobj__parent(b)
      b.__mobj__parent(a)

      a.__mobj__root.should == a
      b.__mobj__root.should == a
      c.__mobj__root.should == a

      c.__mobj__parent.should == b
      b.__mobj__parent.should == a

      d = { a: Object.new, b:[ 1, 2, { c: { d: [ {e: Object.new }, {e: Object.new} ] } } ] }

      d[:a].__mobj__parent.should be_nil
      d[:b].__mobj__parent.should be_nil
      d[:b][2].__mobj__parent.should be_nil
      d[:b][2][:c].__mobj__parent.should be_nil
      d[:b][2][:c][:d].__mobj__parent.should be_nil
      d[:b][2][:c][:d].first.__mobj__parent.should be_nil
      d[:b][2][:c][:d].last.__mobj__parent.should be_nil

      d.__mobj__reparent

      d[:b][2][:c][:d].last.__mobj__parent.should == d[:b][2][:c][:d]
      d[:b][2][:c][:d].first.__mobj__parent.should == d[:b][2][:c][:d]
      d[:b][2][:c][:d].__mobj__parent.should == d[:b][2][:c]
      d[:b][2][:c].__mobj__parent.should == d[:b][2]
      d[:b][2].__mobj__parent.should == d[:b]
      d[:b].__mobj__parent.should == d
      d[:a].__mobj__parent.should == d

      d[:b][2][:c][:d].last.__mobj__root.should == d
      d[:b][2][:c][:d].first.__mobj__root.should == d
      d[:b][2][:c][:d].__mobj__root.should == d
      d[:b][2][:c].__mobj__root.should == d
      d[:b][2].__mobj__root.should == d
      d[:b].__mobj__root.should == d
      d[:a].__mobj__root.should == d
    end
  end

  describe Class do
    it "should have helper methods to get it's methods" do
      StringScanner.object_methods.should == [:<<, :[], :beginning_of_line?, :bol?, :check, :check_until, :clear, :concat, :empty?, :eos?, :exist?, :get_byte, :getbyte, :getch, :match?, :matched, :matched?, :matched_size, :peek, :peep, :pointer, :pointer=, :pos, :pos=, :post_match, :pre_match, :reset, :rest, :rest?, :rest_size, :restsize, :scan, :scan_full, :scan_until, :search_full, :skip, :skip_until, :string, :string=, :terminate, :unscan]
      StringScanner.class_methods.should == [:must_C_version]
      StringScanner.defined_methods.should == [:<<, :[], :beginning_of_line?, :bol?, :check, :check_until, :clear, :concat, :empty?, :eos?, :exist?, :get_byte, :getbyte, :getch, :match?, :matched, :matched?, :matched_size, :must_C_version, :peek, :peep, :pointer, :pointer=, :pos, :pos=, :post_match, :pre_match, :reset, :rest, :rest?, :rest_size, :restsize, :scan, :scan_full, :scan_until, :search_full, :skip, :skip_until, :string, :string=, :terminate, :unscan]
    end
  end

  describe Array do

    it "can sum and avg" do

      [1.3,2,3,'4','five',nil].msum.should == 10.3
      [1.5,2.5,4,'4','five',nil].mavg.should == 2.0

    end

    it "can select the first block that return non-nil" do
      count = 0
      [1,2,3,4,5].return_first { |i| count += 1; i == 3 ? "found" : nil }.should == "found"
      count.should == 3
    end
    
    it "can sequester into a single result" do
      [1].sequester.should == 1
      [1,2].sequester.should == [1, 2]

      [1,nil].sequester.should == 1
      [nil].sequester.should == nil
      [nil, nil].sequester.should == nil

      [1,nil].sequester(true).should == 1
      [1,nil].sequester(false).should == [1, nil]

      [nil].sequester(true).should == nil
      [nil].sequester(false).should == nil

      [nil, nil].sequester(true).should == nil
      [nil, nil].sequester(false).should == [nil, nil]

      [[]].sequester.should == []
    end
  end

  describe Hash do
    it "can do cool things" do
      hash = { :a => 'aaa', 'b' => :bbb, :zero => 0 }
      hash.a.should == 'aaa'
      hash.b.should == :bbb

      hash[:a].should == 'aaa'
      hash['a'].should == 'aaa'
      hash[:b].should == :bbb
      hash['b'].should == :bbb
      hash.c.should be_nil

      expect { hash.c! }.to raise_exception

      hash[5, nil, :foo, 'b'].should == :bbb
      hash[5, nil, :foo, :a].should == 'aaa'

      hash.a?.should be_true
      hash.b?.should be_true
      hash.zero?.should be_true
      hash.c?.should be_false

      hash.a = 'new a'
      hash.b = nil
      hash.c = 15

      hash.should == {
          a: 'new a',
          'b' => nil,
          c: 15,
          zero: 0
      }

      hash[:b].should be_nil
      hash['b'].should be_nil
      hash.b.should be_nil

      hash.c { |val| val + 10 }.should == 25
      hash.c? { |val| "v:#{val}" }.should == 'v:true'
      hash.g? { |val| "v:#{val}" }.should == 'v:false'

      hash.symvert.should == {a:"new a", "b"=>nil, zero:0, c:15}
      hash.symvert(:to_s).should == {"a"=>"new a", "b"=>"", "zero"=>"0", "c"=>"15"}
      hash.symvert(:to_sym).should == {a: :"new a", b: nil, zero: 0, c: 15}
      hash.symvert(:sym).should == {a: :"new a", b: :"", zero: :"0", c: :"15"}
      hash.symvert(:to_s, :sym).should == {"a"=>:"new a", "b"=>:"", "zero"=>:"0", "c"=>:"15"}
      hash.symvert(proc { |k| "[#{k}]" }, proc { |v| "(#{v})" }).should == {"[a]"=>"(new a)", "[b]"=>"()", "[zero]"=>"(0)", "[c]"=>"(15)"}
      hash.symvert(proc { |k,v| "[#{k}=#{v}]" }, proc { |k,v| "(#{k}=#{v})" }).should == {"[a=new a]"=>"(a=new a)", "[b=]"=>"(b=)", "[zero=0]"=>"(zero=0)", "[c=15]"=>"(c=15)"}

      hash.h { |val| val.nil? }.should be_true
      hash.h('default').should == 'default'
      hash.h.should be_nil
      hash.h!('saved default').should == 'saved default'
      hash.h.should == 'saved default'
      hash.i!('saved default') { |i| "#{i} from block" }.should == 'saved default from block'
      hash.i.should == 'saved default from block'

    end
  end

  describe MatchData do
    it "can hash out named captures" do
      "abc".match(/(?<a>.)(?<b>.)(?<c>.)(?<d>.)?/).to_hash.should == { a: 'a', b: 'b', c: 'c', d: nil }
    end

    it "can get named captures via method call" do
      m = "abc".match(/(?<first>.)(?<second>.)(?<third>.)(?<last>.)?/)
      m.first.should == "a"
      m.second.should == "b"
      m.third.should == "c"
      m.last.should be_nil

      m.first?.should be_true
      m.second?.should be_true
      m.third?.should be_true
      m.last?.should be_false
    end
  end

  describe Mobj::Token do
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
          lookval: { o: [ "i.j.k", "l.m.n" ] },
          up: { a: { val: "wrong" }, val: "right" }
      }

      Mobj::Token.new(:path, "a").walk(obj).should == obj[:a]
      Mobj::Token.new(:path, "not_found").walk(obj).should == nil

      Mobj::Token.new(:root,
                      Mobj::Token.new(:path, :b),
                      Mobj::Token.new(:path, :c),
                      Mobj::Token.new(:path, :d)).walk(obj).should == [ "foundA", "foundB"]

      Mobj::Token.new(:root,
                      Mobj::Token.new(:path, :b),
                      Mobj::Token.new(:path, :not_found),
                      Mobj::Token.new(:path, :d)).walk(obj).should == [nil, nil]

      Mobj::Token.new(:root,
                      Mobj::Token.new(:path, :c),
                      Mobj::Token.new(:path, :d)).walk(obj).should == [ 'f0','f1','f2','f3','f4','f5','f6', 'f7' ]
      Mobj::Token.new(:root,
                      Mobj::Token.new(:path, :c)).walk(obj).should == [ {d:'f0'}, {d:'f1'}, {d:'f2'}, {d:'f3'}, {d:'f4'}, {d:'f5'}, {d:'f6'}, {d:'f7'} ]
      Mobj::Token.new(:path, :d, indexes: [1, 2..4, 5...7, 8..-1]).walk(obj).should == [ 1, 2, 3, 4, 5, 6, 8, 9 ]
      Mobj::Token.new(:literal, :foo).walk(obj).should == "foo"
      Mobj::Token.new(:any,
                      Mobj::Token.new(:path, :e),
                      Mobj::Token.new(:path, :f),
                      Mobj::Token.new(:path, :g),
                      Mobj::Token.new(:path, :h)).walk(obj).should == "found by any"
      Mobj::Token.new(:each,
                      Mobj::Token.new(:path, :e),
                      Mobj::Token.new(:path, :f),
                      Mobj::Token.new(:path, :g),
                      Mobj::Token.new(:path, :h)).walk(obj).should == [nil, nil, "found by any", "not any"]
      Mobj::Token.new(:all,
                      Mobj::Token.new(:path, :e),
                      Mobj::Token.new(:path, :f),
                      Mobj::Token.new(:path, :g),
                      Mobj::Token.new(:path, :h)).walk(obj).should == nil
      Mobj::Token.new(:all,
                      Mobj::Token.new(:path, :g),
                      Mobj::Token.new(:path, :h)).walk(obj).should == [ "found by any", "not any" ]
      Mobj::Token.new(:regex, /foo_.*/).walk(obj).should == [ "regex0", "regex1", "regex2" ]
      Mobj::Token.new(:lookup, Mobj::Token.new(:root, Mobj::Token.new(:path, :lookval), Mobj::Token.new(:path, :o))).walk(obj).should == [ "found0", "found1", "found2", "found3" ]

      Mobj::Token.new(:root,
                      Mobj::Token.new(:path, :up),
                      Mobj::Token.new(:path, :a),
                      Mobj::Token.new(:up),
                      Mobj::Token.new(:path, :val)).walk(Mobj::Circle.wrap(obj)).should == "right"

    end

    it "keeps parents proper when walking" do
      complex = {
          a:{ people: [ { employee_id: 0, company_id: 0 }, { employee_id: 1, company_id: 0 }] },
          b:[
              { company: 0, employees: [ { empid: 0, name: "Joe" }, { empid: 1, name: "Sally" } ] },
              { company: 1, employees: [ { empid: 0, name: "Wong"}, { empid: 1, name: "Wright"} ] }
          ]
      }

      ret = "b.employees".tokenize.walk(complex)
      ret.should == [{:empid=>0, :name=>"Joe"}, {:empid=>1, :name=>"Sally"}, {:empid=>0, :name=>"Wong"}, {:empid=>1, :name=>"Wright"}]
      ret[0].__mobj__parent.__mobj__parent.should == { company: 0, employees: [ { empid: 0, name: "Joe" }, { empid: 1, name: "Sally" } ] }
      ret[1].__mobj__parent.__mobj__parent.should == { company: 0, employees: [ { empid: 0, name: "Joe" }, { empid: 1, name: "Sally" } ] }
      ret[2].__mobj__parent.__mobj__parent.should == { company: 1, employees: [ { empid: 0, name: "Wong"}, { empid: 1, name: "Wright"} ] }
      ret[3].__mobj__parent.__mobj__parent.should == { company: 1, employees: [ { empid: 0, name: "Wong"}, { empid: 1, name: "Wright"} ] }

      "b.employees".walk(complex).should == ret
    end
  end

  describe String do

    it "can scan returning actual match data" do
      foo = ['a', 'c']
      bar = ['b', 'd']

      "abcd".matches(/(?<foo>.)(?<bar>.)/) do |match|
        match.foo.should == foo.shift
        match.bar.should == bar.shift
      end

      foo.should be_empty
      bar.should be_empty
    end

    it "can parse itself into path tokens" do
      path = "a.b1|b2|~lit.c[0, 0- 0, 0 . . 0,0...0, 0+]./de/.f&g.{{h}}.j,k,l./(m).|&\\{\\[/.n.!o.{{p.q}}.r&s|t,u.^.v"

      path.tokenize.to_s.should ==
          Mobj::Token.new(:root,
                          Mobj::Token.new(:path, :a),
                          Mobj::Token.new(:any, Mobj::Token.new(:path, "b1"), Mobj::Token.new(:path, "b2"), Mobj::Token.new(:literal, "lit")),
                          Mobj::Token.new(:path, "c", :indexes => [0, 0..0, 0..0, 0...0, 0..-1]),
                          Mobj::Token.new(:regex, /de/),
                          Mobj::Token.new(:all, Mobj::Token.new(:path, "f"), Mobj::Token.new(:path, "g")),
                          Mobj::Token.new(:lookup, Mobj::Token.new(:path, "h")),
                          Mobj::Token.new(:each, Mobj::Token.new(:path, "j"), Mobj::Token.new(:path, "k"), Mobj::Token.new(:path, "l")),
                          Mobj::Token.new(:regex, /(m).|&\{\[/),
                          Mobj::Token.new(:path, "n"),
                          Mobj::Token.new(:inverse, Mobj::Token.new(:path, "o")),
                          Mobj::Token.new(:lookup, Mobj::Token.new(:root, Mobj::Token.new(:path, "p"), Mobj::Token.new(:path, "q"))),
                          Mobj::Token.new(:each, Mobj::Token.new(:all,
                                                                 Mobj::Token.new(:path, "r"),
                                                                 Mobj::Token.new(:any, Mobj::Token.new(:path, "s"), Mobj::Token.new(:path, "t"))), Mobj::Token.new(:path, "u")),
                          Mobj::Token.new(:up),
                          Mobj::Token.new(:path, "v")

          ).to_s
    end

    it "can walk a path" do
      obj = {
          name: { first: "Joe", last: "Smith" },
          ids: [ 1, 3, 5, 16, 941, 13, 100, 3, 0, 104 ],
          auth_tokens: [ { provider: { name: "example.com", id:1 }, token: { auth: "123456", expire: "10-20-2012" } },
                         { provider: { name: "site.com", id:2 }, token: { authentication_token: "891011", date: "10-20-2013" } }
          ],
          primary_key: { path: "auth_tokens.provider" }
      }

      :name.walk(obj).should == { first:"Joe", last:"Smith" }

      "name.first".walk(obj).should == "Joe"

      "name./\\w\\w.*/".walk(obj).should == ["Joe", "Smith"]

      "name./\\w(\\w).*/".walk(obj).should == { "i" => "Joe", "a" => "Smith" }

      "name./(?:(?<fn>fir)|(?<ln>las)).*/".walk(obj).should == { :fn => "Joe", :ln => "Smith" }

      "name.first , last".walk(obj).should == ["Joe", "Smith"]

      "ids[1, 3, 5..7, 9+]".walk(obj).should == [3, 16, 13, 100, 3, 104]

      "auth_tokens.token./^auth/.*to_i".walk(obj).should == [ 123456, 891011 ]

      "auth_tokens.token.expire | date".walk(obj).should == [ "10-20-2012", "10-20-2013" ]

      "/auth/.provider, token.auth | authentication_token|~N/A".walk(obj).should == ["N/A", "N/A", "123456", "891011"]

      "{{primary_key.path}}.id".walk(obj).should == [1, 2]
    end
  end

  describe Mobj::Circle do
    it "can keep track of it's parent" do
      ch = Mobj::CircleHash.new
      ca = Mobj::CircleRay.new
      ch['foo'] = 'bar'
      ch.foo.should == "bar"
      ch['foo'].should == "bar"
      ch[:foo].should == "bar"
      ch.foo.__mobj__parent.should == ch

      ca[0] = "hello"
      ca[5..7] = "world"

      ca[0].should == "hello"
      ca[5] = "world"
      ca[6] = "world"
      ca[7] = "world"

      ca.first.__mobj__parent.should == ca
    end

    it "can wrap nested arrays and hashes" do
      noncirc = { foo: [ 1, 2, 3, 4], bar: { baz: 'hello', biz: 'world', whiz: [ { innera: 1 }, { innerb: 1 }, { innerc: 1 } ]}}
      circle = Mobj::Circle.wrap(noncirc)

      circle.foo.should == [1, 2, 3, 4]
      circle.bar.should == { baz: 'hello', biz: 'world', whiz: [ { innera: 1 }, { innerb: 1 }, { innerc: 1 } ]}
      circle.bar.baz.should == 'hello'
      circle.bar.biz.should == 'world'
      circle.bar.whiz.should == [ { innera: 1 }, { innerb: 1 }, { innerc: 1 } ]
      circle.bar.whiz.first.innera.should == 1
      circle.bar.whiz.last.innerc.should == 1

      circle.__mobj__parent.should be_nil
      circle.bar.__mobj__parent.should == circle
      circle.bar.whiz.__mobj__parent.should == circle.bar
      circle.bar.whiz.last.__mobj__parent.should == circle.bar.whiz
      circle.bar.whiz.last.innerc.__mobj__parent.should == circle.bar.whiz.last
    end
  end
end

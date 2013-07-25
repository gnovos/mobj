require 'spec_helper'

describe Mobj do

  describe ::String do

    it "can call methods" do

      foo = "100.81"

      "to_f".walk(foo).should == 100.81

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
                      Mobj::Token.new(:path, :val)).walk(Mobj::Circle.wrap!(obj)).should == "right"

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

end

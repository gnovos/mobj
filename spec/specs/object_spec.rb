require 'spec_helper'

describe Mobj do

  describe Object do

    it "has shortcuts" do
      [].a?.should be_true
      {}.h?.should be_true
      {}.c?.should be_true
      [].c?.should be_true

      "".s?.should be_true
      1.i?.should be_true
      1.1.f?.should be_true
      50.n?.should be_true
      50.1.n?.should be_true
      ->{}.p?.should be_true
    end

    it "has if(and only if)?" do
      "not nil".iff?('foo').should == 'foo'
      nil.iff?('foo').should be_nil
      false.iff?('foo').should be_nil

      "not nil".iff? { reverse }.should == 'lin ton'
      nil.iff? { reverse } .should be_nil
      false.iff? { reverse } .should be_nil
    end

    it "has a shortcut for if/then" do

      "true".tru?("this", "not").should == "this"
      "true".tru? { "yep" }.should == "yep"

      "true".fals?("this").should be_nil
      "true".fals?{ "yep" }.should be_nil

      nil.tru?("this", "not").should == "not"
      nil.tru?{ "yep" }.should be_false

      nil.fals?("this").should == "this"
      nil.fals?{ "yep" }.should == "yep"

    end

    it "can be altered and replaced" do
      o = { foo: 'foo', bar: 'bar' }
      o.alter! { self.foo }.should == 'foo'
      o.alter! {  }.should be_nil
      o.alter!('val'){ |v| "#{v}=#{self.foo}" }.should == 'val=foo'
    end

    it "can when" do
      o = Object.new
      def o.foo_true() true end
      def o.foo_false() false end
      def o.bar() "bar" end
      def o.baz() "baz" end
      def o.val(v=nil) block_given? ? yield(v) : v end
      o.when.foo_true.then.bar.else.baz.should == "bar"
      o.when.foo_false.then.bar.else.baz.should == "baz"
      o.when.foo.then.bar.else.baz.should == "baz"

      o.when.foo_true.bar.should == "bar"
      o.when.foo_false.bar.should == o

      o.if?.foo_true.then.bar.else.baz.should == "bar"

      o.if?.val(true).then.bar.else.baz.should == "bar"
      o.if?.val(false).then.bar.else.baz.should == "baz"

      o.if?.val(true).bar == "bar"
      o.if?.val(false).bar == o

      o.if?.val{true}.bar == "bar"
      o.if?.val{false}.bar == o

      o.if?.val(true){|a| !a }.bar == o
      o.if?.val(false){|a| !a }.bar == "bar"

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

end

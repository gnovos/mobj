require 'spec_helper'

describe Mobj do

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

end

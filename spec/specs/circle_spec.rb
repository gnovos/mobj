require 'spec_helper'

describe Mobj do

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

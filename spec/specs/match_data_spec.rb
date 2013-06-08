require 'spec_helper'

describe Mobj do

  describe MatchData do
    it "can hash out named captures" do
      "abc".match(/(?<a>.)(?<b>.)(?<c>.)(?<d>.)?/).to_h.should == { a: 'a', b: 'b', c: 'c', d: nil }
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

end

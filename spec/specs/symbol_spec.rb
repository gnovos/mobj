require 'spec_helper'

describe Mobj do

  describe ::Symbol do
    it "can act like a string" do
      :"0x1a".hex.should == 26
    end

    it "can sym" do
      :foo.sym.should == :foo
    end

  end

end

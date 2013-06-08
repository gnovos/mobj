require 'spec_helper'

describe Mobj do

  describe ::Float do
    it "can delimit" do
      1234567890.234.delimit.should == "1,234,567,890.234"
      1.5.delimit.should == "1.5"
      123.1234.delimit.should == "123.1234"
    end
  end

end

require 'spec_helper'

describe Mobj do

  describe Class do
    it "should have helper methods to get it's methods" do
      StringScanner.object_methods.should == [:<<, :[], :beginning_of_line?, :bol?, :check, :check_until, :clear, :concat, :empty?, :eos?, :exist?, :get_byte, :getbyte, :getch, :match?, :matched, :matched?, :matched_size, :peek, :peep, :pointer, :pointer=, :pos, :pos=, :post_match, :pre_match, :reset, :rest, :rest?, :rest_size, :restsize, :scan, :scan_full, :scan_until, :search_full, :skip, :skip_until, :string, :string=, :terminate, :unscan]
      StringScanner.class_methods.should == [:must_C_version]
      StringScanner.defined_methods.should == [:<<, :[], :beginning_of_line?, :bol?, :check, :check_until, :clear, :concat, :empty?, :eos?, :exist?, :get_byte, :getbyte, :getch, :match?, :matched, :matched?, :matched_size, :must_C_version, :peek, :peep, :pointer, :pointer=, :pos, :pos=, :post_match, :pre_match, :reset, :rest, :rest?, :rest_size, :restsize, :scan, :scan_full, :scan_until, :search_full, :skip, :skip_until, :string, :string=, :terminate, :unscan]
    end
  end

end

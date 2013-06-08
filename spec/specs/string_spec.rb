require 'spec_helper'

describe Mobj do

  describe String do

    it "can color format" do

      cf = "{y!^|this %0.2f} {b*U|is} {g|%s} color {_x|test} %s"

      cf.cfmt.should == "\e[93;1mthis %0.2f\e[m \e[94;21mis\e[m \e[32m%s\e[m color \e[30;4;5mtest\e[m %s"

      (cf & [1.2, "foo", "bar"]).should == "\e[93;1mthis 1.20\e[m \e[94;21mis\e[m \e[32mfoo\e[m color \e[30;4;5mtest\e[m bar"


    end

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
  end

end

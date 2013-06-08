require 'spec_helper'

describe Mobj do

  describe Array do

    it "can apply" do

      %w(to_s sym to_i to_f to_f.round to_f.floor to_f.floor.to_s.reverse.to_i).apply('104.81').should == [
        '104.81', :'104.81', 104, 104.81, 105, 104, 401
      ]

    end

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

    it "can msym" do
      [1, 2, 'a', :b].msym.should == [:'1', :'2', :a, :b]
    end

    it "can meach" do

      ['a', 'b', 'c'].meach(:sym).should == [:a, :b, :c]
      [1.002, 1.345, 23.99766].meach(2, &:round).should == [1.0, 1.35, 24.0]

      [1.002, 1.345, 23.99766].meach(:round, 2).should == [1.0, 1.35, 24.0]

    end

  end

end

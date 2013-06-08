require 'spec_helper'

describe Mobj do

  describe Hash do
    it "can apply" do

      target = [1, 2, 3, 4, 5]

      {
        unshift:100,
        delete:4,
        reverse:nil
      }.apply!(target).should == [[100, 1, 2, 3, 5], 4, [5, 3, 2, 1, 100]]

      target.should == [100, 1, 2, 3, 5]

    end

    it "can do cool things" do
      hash = { :a => 'aaa', 'b' => :bbb, :zero => 0 }
      hash.a.should == 'aaa'
      hash.b.should == :bbb

      hash[:a].should == 'aaa'
      hash['a'].should == 'aaa'
      hash[:b].should == :bbb
      hash['b'].should == :bbb
      hash.cc.should be_nil

      expect { hash.cc! }.to raise_exception

      hash[5, nil, :foo, 'b'].should == :bbb
      hash[5, nil, :foo, :a].should == 'aaa'

      hash.a?.should be_true
      hash.b?.should be_true
      hash.zero?.should be_true
      hash.cc?.should be_false

      hash.a = 'new a'
      hash.b = nil
      hash.cc = 15

      hash.should == {
          a: 'new a',
          'b' => nil,
          cc: 15,
          zero: 0
      }

      hash[:b].should be_nil
      hash['b'].should be_nil
      hash.b.should be_nil

      hash.cc { |val| val + 10 }.should == 25
      hash.cc? { |val| "v:#{val}" }.should == 'v:true'
      hash.g? { |val| "v:#{val}" }.should == 'v:false'

      hash.symvert.should == {a:"new a", "b"=>nil, zero:0, cc:15}
      hash.symvert(:to_s).should == {"a"=>"new a", "b"=>"", "zero"=>"0", "cc"=>"15"}
      hash.symvert(:to_sym).should == {a: :"new a", b: nil, zero: 0, cc: 15}
      hash.symvert(:sym).should == {a: :"new a", b: :"", zero: :"0", cc: :"15"}
      hash.symvert(:to_s, :sym).should == {"a"=>:"new a", "b"=>:"", "zero"=>:"0", "cc"=>:"15"}
      hash.symvert(proc { |k| "[#{k}]" }, proc { |v| "(#{v})" }).should == {"[a]"=>"(new a)", "[b]"=>"()", "[zero]"=>"(0)", "[cc]"=>"(15)"}
      hash.symvert(proc { |k,v| "[#{k}=#{v}]" }, proc { |k,v| "(#{k}=#{v})" }).should == {"[a=new a]"=>"(a=new a)", "[b=]"=>"(b=)", "[zero=0]"=>"(zero=0)", "[cc=15]"=>"(cc=15)"}

      hash.h { |val| val.nil? }.should be_true
      hash.h('default').should == 'default'
      hash.h.should be_nil
      hash.h!('saved default').should == 'saved default'
      hash.h.should == 'saved default'
      hash.ii!('saved default') { |i| "#{i} from block" }.should == 'saved default from block'
      hash.ii.should == 'saved default from block'

    end
  end

end

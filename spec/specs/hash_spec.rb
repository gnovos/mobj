require 'spec_helper'

describe Mobj do

  describe Hash do

    it "can remove nil keys and values" do
      {
        a:nil,
        nil => 'b',
        c:'d'
      }.denil!.should == { c:'d' }
    end

    it "has shortcuts" do
      {}.mt?.should be_true
      { a:1 }.mt?.should be_false
    end

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
      hash = { :aa => 'aaa', 'b' => :bbb, :zero => 0 }
      hash.aa.should == 'aaa'
      hash.b.should == :bbb

      hash[:aa].should == 'aaa'
      hash['aa'].should == 'aaa'
      hash[:b].should == :bbb
      hash['b'].should == :bbb
      hash.cc.should be_nil

      expect { hash.cc! }.to raise_exception

      hash[5, nil, :foo, 'b'].should == :bbb
      hash[5, nil, :foo, :aa].should == 'aaa'

      hash.aa?.should be_true
      hash.b?.should be_true
      hash.zero?.should be_true
      hash.cc?.should be_false

      hash.aa = 'new a'
      hash.b = nil
      hash.cc = 15

      hash.should == {
          aa: 'new a',
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

      hash.symvert.should == {aa:"new a", "b"=>nil, zero:0, cc:15}
      hash.symvert(:to_s).should == {"aa"=>"new a", "b"=>"", "zero"=>"0", "cc"=>"15"}
      hash.symvert(:to_sym).should == {aa: :"new a", b: nil, zero: 0, cc: 15}
      hash.symvert(:sym).should == {aa: :"new a", b: :"", zero: :"0", cc: :"15"}
      hash.symvert(:to_s, :sym).should == {"aa"=>:"new a", "b"=>:"", "zero"=>:"0", "cc"=>:"15"}
      hash.symvert(proc { |k| "[#{k}]" }, proc { |v| "(#{v})" }).should == {"[aa]"=>"(new a)", "[b]"=>"()", "[zero]"=>"(0)", "[cc]"=>"(15)"}
      hash.symvert(proc { |k,v| "[#{k}=#{v}]" }, proc { |k,v| "(#{k}=#{v})" }).should == {"[aa=new a]"=>"(aa=new a)", "[b=]"=>"(b=)", "[zero=0]"=>"(zero=0)", "[cc=15]"=>"(cc=15)"}

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

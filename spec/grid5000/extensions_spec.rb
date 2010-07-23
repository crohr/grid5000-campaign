require File.dirname(__FILE__)+"/../spec_helper"

describe "extensions" do
  describe Fixnum do
    it "should have a :nodes method" do
      50.nodes.should == 50
    end
  end
  
  describe Symbol do
    it "should have a :gt method" do
      result = :symbol.gt(50)
      result.should be_a(Proc)
      result.call("symbol" => 49).should be_false
      result.call("symbol" => 50).should be_true
      result.call("symbol" => 51).should be_true
    end
    
    it "should have a :eq method" do
      result = :clock_speed.eq(1.G)
      result.should be_a(Proc)
      result.call("clock_speed" => 1.G).should be_true
      result.call("clock_speed" => 2.G).should be_false
    end
    
    it "should have a :lt method" do
      result = :clock_speed.lt(50)
      result.should be_a(Proc)
      result.call("clock_speed" => 49).should be_true
      result.call("clock_speed" => 50).should be_true
      result.call("clock_speed" => 51).should be_false
    end
    
    it "should have a :in method" do
      result = :clock_speed.in(1.G...2.G)
      result.should be_a(Proc)
      result.call("clock_speed" => 1.G).should be_true
      result.call("clock_speed" => 2.G).should be_false
    end
    
    it "should have a :like method" do
      result = :interface.like(/infiniband/, /ethernet/)
      result.should be_a(Proc)
      result.call("interface" => "infiniband10").should be_true
      result.call("interface" => "10ethernet").should be_true
      result.call("interface" => "eth").should be_false
    end
    
    it "should raise an error if :like is passed at least one non-regexp expression" do
      lambda{
        :interface.like(/infiniband/, "ethernet")
      }.should raise_error(ArgumentError, /is not a regular expression/)
    end
    
    it "should have a :with method" do
      result = :processor.with(:clock_speed.in(1.G...2.G))
      result.should == :processor
      :processor.conditions.length.should == 1
    end
    
    it "should have a :and method" do
      result = :processor.with(:clock_speed.in(1.G...2.G)).
                  and(:something.gt(50))
      result.should == :processor
      :processor.conditions.length.should == 2
    end
    
    
    it "should work for array values" do
      hash = {
        "network_adapters" => [
          {"enabled" => true, "interface" => "infiniband", "rate" => 1000}
        ]
      }
      result = :network_adapters.with(
        :interface.like(/infiniband/, /ethernet/)
      )
      result.conditions.all?{|condition|
        condition.call(hash)
      }.should be_true
    end
    
    it "should raise an error if :and is called and no conditions are already set" do
      pending
    end
  end
end
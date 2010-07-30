require File.dirname(__FILE__)+"/../../spec_helper"

describe "extensions" do
  describe Fixnum do
    it "should have a :nodes method" do
      50.nodes.should == 50
    end
  end
  
  describe Symbol do
    it "should have a :gt method" do
      result = :symbol.gt(50)
      result.should be_a(Symbol::Requirement)
      result.symbol.should == :symbol
      result.should_not be_matched("symbol" => 49)
      result.should be_matched("symbol" => 50)
      result.should be_matched("symbol" => 51)
    end
    
    it "should have a :eq method" do
      result = :clock_speed.eq(1.G)
      result.should be_matched("clock_speed" => 1.G)
      result.should_not be_matched("clock_speed" => 2.G)
    end
    
    it "should have a :lt method" do
      result = :clock_speed.lt(50)
      result.should be_matched("clock_speed" => 49)
      result.should be_matched("clock_speed" => 50)
      result.should_not be_matched("clock_speed" => 51)
    end
    
    it "should have a :in method that accepts range" do
      result = :clock_speed.in(1.G...2.G)
      result.should be_matched("clock_speed" => 1.G)
      result.should_not be_matched("clock_speed" => 2.G)
    end
    
    it "should have a :in method that accepts arrays" do
      result = :clock_speed.in([1.G, 2.G])
      result.should be_matched("clock_speed" => 1.G)
      result.should be_matched("clock_speed" => 2.G)
      result.should_not be_matched("clock_speed" => 1.5.G)
    end
    
    it "should have a :in method that accepts splats" do
      result = :system_state.in("free", "besteffort")
      result.should be_matched("system_state" => "free")
      result.should be_matched("system_state" => "besteffort")
      result.should_not be_matched("system_state" => "unknown")
    end
    
    it "should have a :like method" do
      result = :interface.like(/infiniband/, /ethernet/)
      result.should be_matched("interface" => "infiniband10")
      result.should be_matched("interface" => "10ethernet")
      result.should_not be_matched("interface" => "eth")
    end
    
    it "should raise an error if :like is passed at least one non-regexp expression" do
      lambda{
        :interface.like(/infiniband/, "ethernet")
      }.should raise_error(ArgumentError, /is not a regular expression/)
    end
    
    it "should have a :with method" do
      result = :processor.with(:clock_speed.in(1.G...2.G))
      result.conditions.length.should == 1
    end
    
    it "should have a :and method" do
      result = :processor.with(:clock_speed.in(1.G...2.G)).
                  and(:something.gt(50))
      result.symbol.should == :processor
      result.conditions.length.should == 2
    end
    
    it "should return the condition as conditions if conditions is empty " do
      result = :clock_speed.in(1.G...2.G)
      result.conditions.length.should == 1
    end
    
    it "should work for hash values" do
      p "here !"
      hash = {
        "status" => {
          "system_state" => "free",
          "hardware_state" => "alive",
        }
      }
      hash = {
        "status" => {"system_state"=>"free", "node_uid"=>"griffon-19", "uid"=>1280494406, "hardware_state"=>"alive", "type"=>"node_status", "reservations"=>[{"state"=>"Waiting", "queue"=>"default", "user"=>"mmehdi", "batch_id"=>314240, "start_time"=>1280512800, "walltime"=>43200}], "links"=>[{"href"=>"/sid/grid5000/sites/nancy/clusters/griffon/nodes/griffon-19/status", "rel"=>"self", "type"=>"application/vnd.fr.grid5000.api.NodeStatus+json;level=1"}, {"href"=>"/sid/grid5000/sites/nancy/clusters/griffon/nodes/griffon-19", "rel"=>"parent", "type"=>"application/vnd.fr.grid5000.api.Node+json;level=1"}]}
      }
      result = :status.
        with(:system_state.in('besteffort', 'free')).
        and(:hardware_state.eq('alive'))
      result.should be_matched(hash)
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
      result.should be_matched(hash)
    end
    
    it "should raise an error if :and is called and no conditions are already set" do
      lambda{
        :status.
          and(:system_state.in('besteffort', 'free')).
          and(:hardware_state.eq('alive'))
      }.should raise_error(ArgumentError, /must call :with at least once before :and/)
    end
  end
end
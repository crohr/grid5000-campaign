require File.dirname(__FILE__)+"/../spec_helper"

describe Campaign do
  it "should raise an error if the recipe cannot be read" do
    lambda{
      Campaign.new(nil)
    }.should raise_error(ArgumentError, /Cannot read the given recipe/)
  end
  
  describe "setting options" do
    before do
      @campaign = Campaign.new(File.new(fixture("recipe1.rb")))
    end
    it "should set an option with :set" do
      @campaign.set "option", "value"
      @campaign.config[:option].should == "value"
    end
  end
  
  describe "find" do
    before do
      recipe = StringIO.new(File.read(fixture("recipe1.rb")))
      @campaign = Campaign.new(recipe)
    end
    it "should instantiate a new Requirement" do
      requirement = @campaign.find(40.nodes)
      requirement.should be_a(Campaign::Requirement)
      requirement.campaign.should == @campaign
      requirement.nodes.should == 40
      requirement.properties.should == {}
    end
  end

end
require File.dirname(__FILE__)+"/../../spec_helper"
# 
# describe Campaign::Requirement do
#   before do
#     @campaign = mock(Campaign)
#   end
#   
#   it "should correctly instantiate the requirement" do
#     requirement = Campaign::Requirement.new(@campaign, 40)
#     requirement.campaign.should == @campaign
#     requirement.nodes.should == 40
#     requirement.properties.should == {}
#   end
#   
#   describe "modifiers" do
#     before do
#       @requirement = Campaign::Requirement.new(@campaign, 40)
#     end
#     
#     it "should not allow to set the distribution if locations is empty" do
#       lambda{
#         @requirement.distributed(4, 5, 6)
#       }.should raise_error(ArgumentError, "You must specify at least one location first.")
#     end
#     
#     it "should not allow to set a distribution with more items than the number of locations" do
#       @requirement.on(:rennes, :lille)
#       lambda{
#         @requirement.distributed(4, 5, 6)
#       }.should raise_error(ArgumentError, "Your distribution exceeds the number of locations.")
#     end
#     
#     it "should set the :distribution property [distributed=array]" do
#       @requirement.on(:rennes, :lille)
#       @requirement.distributed(4, 5).should == @requirement
#       @requirement.distribution.should == [4,5]
#     end
#     
#     it "should set the locations if given an array of symbols" do
#       @requirement.on(:rennes, :lille).should == @requirement
#       @requirement.locations.should == ["rennes", "lille"]
#     end
#     
#     it "should populate the required properties" do
#       @requirement.having(
#         :processor.with(:clock_speed.in 1.G..2.G),
#         :network_adapters.
#           with(:enabled.eq true).
#           and(:rate.gt 10.G).
#           and(:interface.like [/infiniband/, /ethernet/])
#       ).should == @requirement
#       @requirement.properties.keys.should == [:processor, :network_adapters]
#       @requirement.properties[:processor].length.should == 1
#       @requirement.properties[:network_adapters].length.should == 3
#     end
#     
#   end
#   
#   describe "matching" do
#     before do
#       @campaign.stub!(:config).and_return({
#         :besteffort => false,
#         :api_uri => "https://api.grid5000.fr",
#         :api_root => "/sid/grid5000"
#       })
#       @campaign.stub!(:api).and_return(Http.new(@campaign.config))
#       @requirement = Campaign::Requirement.new(@campaign, 40).
#         on(:rennes, :lille).
#         distributed(10,30).
#         having(
#           :network_adapters.
#             with(:enabled.eq true).
#             and(:rate.gt 10.G).
#             and(:interface.like [/infiniband/i, /ethernet/i])
#         )
#     end
#     
#     it "should return true if the node matches the requirement" do
#       @requirement.match?({
#         "processor" => {
#           "clock_speed" => 2.G
#         },
#         "network_adapters" => [
#           {
#             "enabled" => true,
#             "rate" => 10.G,
#             "interface" => "Ethernet"
#           }
#         ]
#       }).should be_true
#     end
#     
#     it "should return false if the node does not match the requirement" do
#       @requirement.match?({
#         "processor" => {
#           "clock_speed" => 2.G
#         },
#         "network_adapters" => [
#           {
#             "enabled" => true,
#             "rate" => 6.G,
#             "interface" => "Ethernet"
#           }
#         ]
#       }).should be_false
#     end
#     
#     describe "searching" do
#       before do
#         stub_http_request(:get, "https://api.grid5000.fr/sid/grid5000").
#           to_return(File.read(fixture("get-sid-grid5000")))
#         stub_http_request(:get, "https://api.grid5000.fr/sid/grid5000/sites").
#           to_return(File.read(fixture("get-sid-grid5000-sites")))
#         CLUSTERS_BY_SITE.each do |site, clusters|
#           stub_http_request(:get, "https://api.grid5000.fr/sid/grid5000/sites/#{site}/status").
#             to_return(File.read(
#               fixture("get-sid-grid5000-sites-#{site}-status")
#             ))
#           stub_http_request(:get, "https://api.grid5000.fr/sid/grid5000/sites/#{site}/clusters").
#             to_return(File.read(
#               fixture("get-sid-grid5000-sites-#{site}-clusters")
#             ))
#           clusters.each do |cluster|
#             stub_http_request(:get, "https://api.grid5000.fr/sid/grid5000/sites/#{site}/clusters/#{cluster}/nodes").
#               to_return(File.read(
#                 fixture("get-sid-grid5000-sites-#{site}-clusters-#{cluster}-nodes")
#               ))
#           end
#         end
#       end
#       
#       it "should start searching nodes matching the requirements as soon as a block is passed" do      
#         EM.synchrony do
#           @requirement.having(
#             :processor.with(:clock_speed.gt 2.5.G)
#           ) do |resources|
#             resources.should be_a(Hash)
#             resources[:rennes].length.should == 10
#             resources[:lille].length.should == 30
#           end
#           EM.stop
#         end
#       end
# 
#       it "should raise a MatchingError if the requirement cannot be fulfilled" do
#         EM.synchrony do
#           lambda{
#             @requirement.having(
#               :processor.with(:clock_speed.gt 50.G)
#             ) do |resources|
#               # whatever
#             end
#           }.should raise_error(Campaign::MatchingError, "Cannot find enough nodes matching the requested distribution.")
#           EM.stop
#         end
#       end
#     end # describe "searching"
#     
# 
#   end
#   
# end

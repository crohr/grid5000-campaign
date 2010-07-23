require File.expand_path("spec_helper", File.dirname(__FILE__)+"/..")

describe Http do
  before do
    @http_valid_config = {
      :api_uri => "http://server.ltd"
    }
  end
  
  %w{api_uri}.each do |property|
    it "should raise an error if #{property} is not set" do
      lambda{
        http = Http.new(@http_valid_config.merge(property.to_sym => nil))
      }.should raise_error(ArgumentError)
    end
  end
  
  it "should correctly instantiate the class" do
    http = Http.new(@http_valid_config)
    http.config[:api_uri].should == @http_valid_config[:api_uri]
  end
  
  
  describe "get" do
    before do
      @http = Http.new(@http_valid_config)
    end
    
    it "should get it" do
      stub_http_request(:get, "https://api.grid5000.fr/sid/grid5000").
        to_return(File.read(fixture("get-sid-grid5000")))
      EM.synchrony do
        response = @http.get("https://api.grid5000.fr/sid/grid5000")
        response["uid"].should == "grid5000"
        EM.stop
      end
    end
    
  end

end

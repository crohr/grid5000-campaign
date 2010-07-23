require File.expand_path File.dirname(__FILE__)+"/../spec_helper"

describe Http::Resource do
    
  describe "get" do
    before do
      @http = Http.new({
        :api_uri => "https://api.grid5000.fr"
      })
    end
    
    it "should get it" do
      stub_http_request(:get, "https://api.grid5000.fr/sid/grid5000").
        to_return(File.read(fixture("get-sid-grid5000")))
      stub_http_request(:get, "https://api.grid5000.fr/sid/grid5000/sites").
        to_return(File.read(fixture("get-sid-grid5000-sites")))
      EM.synchrony do
        grid5000 = @http.get("/sid/grid5000")
        grid5000.get(:sites).length.should == 9
        EM.stop
      end
    end
    
  end

end

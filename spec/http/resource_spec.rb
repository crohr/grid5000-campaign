require File.dirname(__FILE__)+"/../spec_helper"

describe Http::Resource do
    
  describe "get" do
    before do
      @http = Http.new
    end
    
    it "should get it" do
      EM.synchrony do
        grid5000 = @http.get("https://localhost:3443/sid/grid5000")
        grid5000.get(:sites).length.should == 9
        EM.stop
      end
    end
    
  end

end

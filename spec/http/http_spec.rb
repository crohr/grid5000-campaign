require File.dirname(__FILE__)+"/../spec_helper"

describe Http do
  it "should correctly instantiate the class" do
    http = Http.new(:username => "login", :password => "password")
    http.config[:username].should == "login"
    http.config[:password].should == "password"
  end
  
  describe "get" do
    before do
      @http = Http.new
    end
    
    it "should get it" do
      EM.synchrony do
        response = @http.get("https://localhost:3443/sid/grid5000")
        response["uid"].should == "grid5000"
        EM.stop
      end
    end
    
  end

end

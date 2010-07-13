require File.dirname(__FILE__)+"/../spec_helper"

describe Http::Collection do
    
  describe "get" do
    before do
      @http = Http.new
    end
    
    it "should get them in parallel" do
      EM.synchrony do
        sites = @http.get("https://localhost:3443/sid/grid5000/sites")
        clusters = []
        sites.each do |site|
          site.get(:clusters).each do |cluster|
            p cluster.get(:nodes).total
          end
        end
        EM.stop
      end
    end
    
  end

end

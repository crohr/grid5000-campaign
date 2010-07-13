require File.dirname(__FILE__)+"/../spec_helper"

describe Http::Collection do
    
  describe "get" do
    before do
      @http = Http.new
    end
    
    it "should get them in parallel" do
      EM.synchrony do
        sites = @http.get("https://localhost:3443/sid/grid5000/sites")        
        sites.pget(:clusters) do |site, clusters|
          p site["uid"]
          clusters.pget(:nodes) do |cluster, nodes|
            p cluster["uid"]
            p nodes.length
          end
        end
        EM.stop
      end
    end
    
  end

end

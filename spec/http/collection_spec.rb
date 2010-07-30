# require File.expand_path File.dirname(__FILE__)+"/../spec_helper"
# 
# describe Http::Collection do
#     
#   describe "get" do
#     before do
#       @http = Http.new({
#         :api_uri => "https://api.grid5000.fr"
#       })
#     end
#     
#     it "should get them in parallel" do
#       stub_http_request(:get, "https://api.grid5000.fr/sid/grid5000/sites").
#         to_return(File.read(fixture("get-sid-grid5000-sites")))
#       CLUSTERS_BY_SITE.each do |site, clusters|
#         stub_http_request(:get, "https://api.grid5000.fr/sid/grid5000/sites/#{site}/clusters").
#           to_return(File.read(
#             fixture("get-sid-grid5000-sites-#{site}-clusters")
#           ))
#         clusters.each do |cluster|
#           stub_http_request(:get, "https://api.grid5000.fr/sid/grid5000/sites/#{site}/clusters/#{cluster}/nodes").
#             to_return(File.read(
#               fixture("get-sid-grid5000-sites-#{site}-clusters-#{cluster}-nodes")
#             ))
#         end
#       end
#       
#       EM.synchrony do
#         sites = @http.get("/sid/grid5000/sites")        
#         sites.pget(:clusters) do |site, clusters|
#           clusters.pget(:nodes) do |cluster, nodes|
#           end
#         end
#         EM.stop
#       end
#     end
#     
#   end
# 
# end

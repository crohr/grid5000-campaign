class Http
  class Collection < Resource
    include Enumerable
    
    def initialize(*args)
      super(*args)
    end # def initialize
    
    # TODO: fetch 'next' link if existing.
    def each(*args, &block)
      properties["items"].each(*args, &block)
    end # def each
    
    # Parallel GETs:
    #   sites.pget(:clusters) { |site, clusters| ... }
    def pget(rel, &block)
      requests = EventMachine::Synchrony::Multi.new
      self.each do |resource|
        requests.add resource["uid"], http.aget(
          resource.uri_of(rel), 
          :head => {
            "Accept" => resource.type_of(rel)
          }
        )
      end
      result = requests.perform
      result.responses[:callback].each do |key, response|
        p response.response_header
        resource = find{|i| i["uid"] == key}
        response = http.handle_response(response, resource.uri_of(:self))
        block.call(resource, response)
      end
    end
    
    def length
      properties["items"].length
    end
    
    def total
      properties["total"]
    end
    
    def populate(properties)
      super(properties)
      if properties["items"]
        properties["items"].map!{|item|
          Resource.new(
            http, 
            uri_of(:self, item["link"]),
            item
          )
        }
      end
    end
    
  end # class Collection
  
end # class Http
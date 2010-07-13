class Http
  class Collection < Resource
    include Enumerable
    
    def initialize(*args)
      super(*args)
      properties["items"].map!{|item|
        Resource.new(
          http, 
          http.link(self, :self)["href"],
          item
        )
      }
    end # def initialize
    
    def each(*args, &block)
      properties["items"].each(*args, &block)
    end # def each
    
    # Parallel GETs:
    #   sites.pget(:clusters) { |site, clusters| ... }
    def pget(rel, &block)
      uris = {}
      requests = EventMachine::Synchrony::Multi.new
      self.each do |item|
        link = http.link(item, rel)
        uris[item["uid"]] = link["href"]
        requests.add item["uid"], http.aget(link["href"])
      end
      result = requests.perform
      result.responses[:callback].each do |key, response|
        site = find{|i| i["uid"] == key}
        response = http.handle_status(uris[key], response)
        block.call(site, response)
      end
    end
    
    def length
      properties["items"].length
    end
    
    def total
      properties["total"]
    end
    
  end # class Collection
  
end # class Http
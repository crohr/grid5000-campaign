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
    
    def length
      properties["items"].length
    end
    
    def total
      properties["total"]
    end
    
  end # class Collection
  
end # class Http
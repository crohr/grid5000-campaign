class Http
  class Resource
    attr_reader :properties, :http, :uri
    
    def initialize(http, uri, properties)
      @http = http
      @uri = uri.to_s
      @properties = properties        
    end # def initialize
    
    def [](key)
      key = key.to_s
      @properties[key]
    end # def []
    
    def []=(key, value)
      @properties[key.to_s] = value
    end # def []=
    
    def get(rel, *args)
      http.get(http.link(self, rel)["href"], *args)
    end
    
  end # class Resource
end # class Http

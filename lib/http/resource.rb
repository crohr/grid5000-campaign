class Http
  class Resource
    attr_reader :properties, :http, :uri
    
    def initialize(http, uri, properties)
      @http = http
      @uri = uri
      @properties = properties        
    end # def initialize
    
    def method_missing
      # TODO: deal with associations
    end
    
    def links
      self["links"] || []
    end
    
    # Returns URI or nil
    def uri_to(rel_or_title)
      match = rel_or_title.to_s
      link = links.find{|link|
        link["rel"] == match || link["title"] == match
      }
      if link.nil?
        nil
      else
        URI.join(uri.to_s, link["href"])
      end
    end
    
    def [](key)
      key = key.to_s
      @properties[key]
    end # def []
    
    def []=(key, value)
      @properties[key.to_s] = value
    end # def []=
    
    # TODO: deal with depth, and includes
    def load(options = {})
      
    end
  end # class Resource
end # class Http

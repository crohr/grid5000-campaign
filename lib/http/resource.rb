class Http
  class Resource
    attr_reader :properties, :http, :uri, :links
    
    def initialize(http, uri, properties = {})
      @http = http
      @uri = uri
      populate(properties)
    end # def initialize    
    
    def respond_to?(method, *args)
      links.has_key?(method.to_s) || super(method, *args)
    end # def respond_to?
    
    def method_missing(method, *args)
      if link = links[method.to_s]
        http.logger.debug "Loading link #{method}, args=#{args.inspect}"
        links[method.to_s] = link.load(*args)
      else
        super(method, *args)
      end
    end # def method_missing
    
    def links
      @links ||= (self["links"] || []).inject({}) {|memo, link|
        if link["title"].nil?
          key = link["rel"]
          klass = (link["type"] =~ /collection/i) ? Collection : Resource
        else
          key = link["title"]
          klass = (link["type"] =~ /collection/i) ? Collection : Resource
        end
        memo.merge(key => klass.new(http, uri_of(key)))
      }
    end # def links
    
    # Returns URI or nil
    def uri_of(rel_or_title, *args)
      link = find_link(rel_or_title, *args)
      if link.nil?
        nil
      else
        URI.join(uri.to_s, link["href"])
      end
    end # def uri_of
    
    def type_of(rel_or_title, *args)
      link = find_link(rel_or_title, *args)
      if link.nil?
        nil
      else
        link["type"]
      end
    end
    
    def has_key?(key)
      @properties.has_key?(key.to_s)
    end
    
    def [](key)
      @properties[key.to_s]
    end # def []
    
    def []=(key, value)
      @properties[key.to_s] = value
    end # def []=
    
    # If :depth is passed and is greater than 0,
    # subresources will be loaded
    def load(options = {})
      options[:head] ||= {}
      if type = type_of(:self)
        options[:head]['Accept'] ||= type
      end
      response = http.get(uri, options)
      populate(response.properties)
      
      if options[:depth] && options[:depth] > 0
        options[:depth] -= 1
        links.each do |rel, link|
          next if [:self, :parent, :next].include?(rel)
          if options[:only] 
            next unless options[:only].include?(rel)
          elsif options[:except]
            next if options[:except].include?(rel)
          else
            link.load(options)
          end
        end
      end
      self
    end # def load
    
    def populate(properties)
      @properties = properties
    end
    
    protected
    def find_link(rel_or_title, links = nil)
      links ||= (self["links"] || [])
      match = rel_or_title.to_s
      links.find{|link|
        link["rel"] == match || link["title"] == match
      }
    end
  end # class Resource
end # class Http

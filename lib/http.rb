require "uri"
require "json"
require "em/iterator"
require "em-synchrony"
require "em-synchrony/iterator"
require "em-synchrony/em-http"
require "http/resource"
require "http/collection"

class Http
  
  class Error < StandardError; end
  
  VERSION = "0.1"
  
  attr_reader :config, :logger

  def initialize(config = {})
    @config = Hash[config.map{ |key,value| 
      [(key.to_sym rescue key) || key, value] 
    }]
    [:base_uri].each do |property|
      raise ArgumentError, ":#{property} property must be set." unless config[property]
    end
    @logger = config[:logger] || Logger.new(STDERR)
  end # def initialize
  
  
  # <tt>uri</tt>:: URI or String
  def get(uri, options = {})
    logger.debug "Getting #{uri}"
    options[:head] = default_headers.merge(options[:head] || {})
    response = EventMachine::HttpRequest.new(uri.to_s).get(options)
    handle_response(response, uri)
  end # def get
  
  def aget(uri, options = {})
    logger.debug "Getting #{uri}"
    options[:head] = default_headers.merge(options[:head] || {})
    EventMachine::HttpRequest.new(uri.to_s).aget(options)
  end
  
  def multi(&block)
    multi = EM::Synchrony::Multi.new
    block.call(multi)
    result = multi.perform
    result.responses[:callback].map do |uri, response|
      handle_response(response, uri)
    end
  end
  
  def root
    get uri_for(config[:root_uri] || "/")
  end # def root
  
  # <tt>uri</tt>:: URI
  def handle_response(response, uri)
    status = response.response_header.status
    case status
    when 200
      body = JSON.parse response.response
      if collection?(response)
        p "COLLECTION"
        Collection.new(self, uri, body)
      else
        p "RESOURCE"
        Resource.new(self, uri, body)
      end
    when 201, 202  
      # follow Location
      get URI.join(uri.to_s, response.response_header["LOCATION"])
    when 204
      true
    when 404
      nil
    else
      p response.response
      raise Error, "Request failed with status: #{status.inspect}."
    end
  end # def handle_status
  
  def default_headers
    @default_headers ||= {
      "Accept" => "application/json",
      "User-Agent" => "em-restfully/#{VERSION}"
    }
  end # def default_headers
  
  
  # def link(resource, rel)
  #   link = resource["links"] && resource["links"].find{|link|
  #     link["rel"] == rel.to_s || link["title"] == rel.to_s
  #   }
  #   if link
  #     link["href"] = URI.join(config[:api_uri], link["href"]).to_s
  #     link
  #   else
  #     nil
  #   end
  # end
  
  def collection?(response)
    response.response_header["CONTENT_TYPE"] =~ /collection/i
  end
  
  # <tt>path</tt>:: URI or String
  # @returns: URI
  def uri_for(path)
    uri = URI.join(config[:base_uri], path.to_s)
    logger.debug [:uri, uri]
    uri
  end
  

end # module Http

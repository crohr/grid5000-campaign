require "uri"
require "json"
require "em/iterator"
require "em-synchrony"
require "em-synchrony/iterator"
require "em-synchrony/em-http"
require "http/resource"
require "http/collection"

class Http
  attr_reader :config

  def initialize(config = {})
    @config = config
    [:api_uri].each do |property|
      raise ArgumentError, ":#{property} property must be set." unless config[property]
    end
  end # def initialize
  
  def get(uri, options = {})
    uri = uri_for(uri).to_s
    options[:head] = default_headers.merge(options[:head] || {})
    response = EventMachine::HttpRequest.new(uri).get(options)
    handle_status(uri, response)
  end # def get
  
  def aget(uri, options = {})
    options[:head] = default_headers.merge(options[:head] || {})
    EventMachine::HttpRequest.new(uri_for(uri).to_s).aget(options)
  end
  
  def root
    get(uri_for(config[:api_root] || "/"))
  end
  
  def handle_status(uri, response)
    status = response.response_header.status
    case status
    when 200
      body = JSON.parse response.response
      if collection?(body)
        Collection.new(self, uri, body)
      else
        Resource.new(self, uri, body)
      end
    when 201, 202  
      # follow Location
      self.get(URI.join(uri, response.response_header.location).to_s)
    when 204
      true
    when 404
      nil
    else
      raise Error, "Request failed with status: #{status}."
    end
  end # def handle_status
  
  def default_headers
    @default_headers ||= {
      "Accept" => "application/json",
      "User-Agent" => "em-restfully/0.1"
    }
  end # def default_headers
  
  
  def link(resource, rel)
    link = resource["links"] && resource["links"].find{|link|
      link["rel"] == rel.to_s || link["title"] == rel.to_s
    }
    if link
      link["href"] = URI.join(config[:api_uri], link["href"]).to_s
      link
    else
      nil
    end
  end
  
  def collection?(response_body)
    response_body.has_key?("items") && 
      response_body["items"].kind_of?(Array) &&
      response_body.has_key?("links") &&
      response_body.has_key?("total")
  end
  
  def uri_for(path)
    uri = URI.join(config[:api_uri], path.to_s)
    uri
  end
  
  class Error < StandardError; end

end # module Http

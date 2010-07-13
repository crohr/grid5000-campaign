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
    @current_uri = nil
  end # def initialize
  
  def get(uri, options = {})
    options[:head] = default_headers.merge(options[:head] || {})
    response = EventMachine::HttpRequest.new(uri.to_s).get(options)
    handle_status(uri.to_s, response)
  end # def get
  
  def root
    get("/")
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
      self.get(URI.join(uri, response.response_header.location))
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
      link["href"] = URI.join(resource.uri, link["href"])
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
  
  class Error < StandardError; end

end # module Http

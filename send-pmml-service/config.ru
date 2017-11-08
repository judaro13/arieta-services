require 'bundler'
require "syro"
require "pry"
require 'net/http'
require 'uri'
require 'json'


class SendPMML
  def initialize(analytic_path, pmml_data)
    uri = URI.parse(analytic_path)
    request = Net::HTTP::Put.new(uri)
    request.content_type = "text/xml"
    request.body = ""
    request.body << pmml_data

    # req_options = {
    #   use_ssl: uri.scheme == "https",
    # }

    # response = Net::HTTP.start(uri.hostname, uri.port, req_options )

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    binding.pry
  end
end


App = Syro.new do
  post do
    message = ""
    begin
      data = JSON.parse(req.body.read)
      message = SendPMML.new(data["analytic_path"], data["analytic_data"])
    rescue Exception => e
      message = e.message
    end
    res.write message
  end
end

run App

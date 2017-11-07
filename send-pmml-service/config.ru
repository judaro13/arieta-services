require 'bundler'
require "syro"
require "pry"
require 'net/http'
require 'uri'
require 'json'


class SendPMML
  def initialize(analytic_path, pmml_data)
    uri = URI.parse(analytic_path)
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request.body = JSON.dump(pmml_data)

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    response
  end
end


App = Syro.new do
  post do
    response = SendPMML.new(req.params["analytic_path"], req.params["pmml_data"])
    res.write response
  end
end

run App

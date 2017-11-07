require 'bundler'

require 'net/http'
require 'uri'
require 'json'

class SendData
  include SuckerPunch::Job

  def perform(data)
    uri = URI.parse(self.post_path)
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request.body = JSON.dump(data)

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
  end
end

class KafkaService
  attr_accessor :last_sent, :queue, :kafka, :post_path
  def initialize
    self.kafka = Kafka.new(
      seed_brokers: ENV["kafka-broker"]
    )
    self.last_sent = Time.now
    self.queue = []
    self.post_path = ENV["post-path"]
  end

  def start_consumer
    kafka.each_message(topic: ENV["kafka-topic"]) do |message|
      if queue.size < 2000 || (Time.now - last_sent) < 10
        queue << message
      else
        SendData.perform_async(self.queue)
        self.last_sent = Time.now
        self.queue = []
      end
    end
  end
end

KafkaService.new

# require 'net/http'
# require 'uri'
#
# uri = URI.parse("http://localhost:8080/openscoring/model/DecisionTreeIris")
# request = Net::HTTP::Post.new(uri)
# request.content_type = "application/json"
# request.body = ""
# request.body << File.read("EvaluationRequest.json").delete("\r\n")
#
# req_options = {
#   use_ssl: uri.scheme == "https",
# }
#
# response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
#   http.request(request)
# end

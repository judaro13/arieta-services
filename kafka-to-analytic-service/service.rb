require 'bundler'

require 'ruby-kafka'
require 'sucker_punch'"
require 'net/http'
require 'uri'
require 'json'

class SendData
  include SuckerPunch::Job
  attr_accessor :kafka, :response_type, :post_path, :response_path, :response_target

  def initialize(post_path, post_response_type, post_response_path )
    self.post_path = post_path
    self.response_type, self.response_target = post_response_type.split(":")
    self.response_path = post_response_path
  end

  def send_to_kafka(response)
    kafka = Kafka.new(
      seed_brokers: self.response_path
    )
    producer = kafka.producer
    JSON.parse(response).each do |r|
      producer.produce(JSON.dump(r), topic: self.response_target)
    end
    producer.deliver_messages

  end

  def send_to_db(response)
    uri = URI.parse(self.response_path+"/"self.response_target)
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request.body = response

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
  end

  def perform(data)
    uri = URI.parse(self.post_path)
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request.body = JSON.dump(data)

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if self.response_type.include?("kafka")
      send_to_kafka(response)
    else
      send_to_db(response)
    end
  end
end

class KafkaService
  attr_accessor :last_sent, :queue, :kafka, :kafka_topic, :send_data
  def initialize
    self.kafka = Kafka.new(
      seed_brokers: ENV["kafka_broker"]
    )
    self.kafka_topic=ENV["kafka_topic"]
    self.last_sent = Time.now
    self.queue = []

    self.send_data = SendData.new(ENV["post_incoming_data_path"], ENV["post_response_type"], ENV["post_response_path"])
  end

  def start_consumer
    kafka.each_message(topic: self.kafka_topic) do |message|
      if queue.size < 2000 || (Time.now - last_sent) < 10
        queue << message
      else
        self.send_data.perform_async(self.queue)
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

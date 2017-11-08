require 'bundler'

require 'ruby-kafka'
require 'pry'
require 'sucker_punch'
require 'net/http'
require 'uri'
require 'json'
require 'csv'


class SendData
  # include SuckerPunch::Job
  attr_accessor :kafka, :response_type, :post_path, :response_path, :response_target, :service_name

  def initialize(service_name, kafka, post_path, post_response_type, post_response_path )
    self.service_name = service_name
    self.kafka = kafka
    #analytic path to model
    self.post_path = post_path
    #to where service response(kafka or to bd) and the target(topic or table/collection)
    self.response_type, self.response_target = post_response_type.split(":")
    #path to db service
    self.response_path = post_response_path
  end

  def send_to_kafka(response, topic, log=false)
    producer = self.kafka.producer
    response.each do |r|
      if log
        producer.produce("{\"#{Time.now }\": \"#{self.service_name}\" => \"#{JSON.dump(r)}\"}", topic: "arieta")
      else
        producer.produce(JSON.dump(r), topic: topic)
      end
    end
    producer.deliver_messages
  rescue Exception => e
    puts e.message
  end

  def send_to_db(response)
    uri = URI.parse(self.response_path+"/"+self.response_target)
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request.body = JSON.dump(response)
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

  end

  def send_statistics
    uri = URI.parse(self.post_path)
    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body)
    send_to_kafka([data], "atieta", true)
  end

  def send_to_analitics(raw_data)
    begin
      csv_string = ::CSV.generate do |csv|
        raw_data.each do |hash|
            csv << hash.values
        end
      end

      uri = URI.parse(self.post_path+"/csv")
      request = Net::HTTP::Post.new(uri)
      request.content_type = "text/plain"
      request.body = ""
      request.body << csv_string

      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end

      csv = CSV.new(response.body, :headers => true, :header_converters => :symbol, :converters => :all)
      parsed_data = []
      csv.to_a.each_with_index do |val,index|
        row = val.to_hash
        row["line"] = index
        parsed_data << row
      end
      send_statistics
      parsed_data
    rescue Exception => e
      send_to_kafka( [{message: e.message}], "atieta", true)
      []
    end
  end

  def perform(raw_data)

    parsed_data = send_to_analitics(raw_data)

    if self.response_type.include?("kafka")
      send_to_kafka(parsed_data, self.response_target) unless parsed_data.empty?
    else
      send_to_db(parsed_data) unless parsed_data.empty?
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

    self.send_data = SendData.new(ENV["service_name"], self.kafka, ENV["post_incoming_data_path"], ENV["post_response_type"], ENV["post_response_path"])
    start_consumer
  end

  def start_consumer
    self.kafka.each_message(topic: self.kafka_topic) do |message|
      if queue.size < 50
        queue << JSON.parse(message.value)
      else
        # self.send_data.perform_async(self.queue)
        self.send_data.perform(self.queue)
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

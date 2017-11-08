

## How to run

```
docker build -t judaro13/kafka-o-analytic-service .

docker run -d -p 3001:3000 judaro13/kafka-o-analytic-service
```

Visit https://localhost:3000/

```
require 'ruby-kafka'
require 'json'
kafka_broker="localhost:9092"
kafka_topic="test"
kafka = Kafka.new(
  seed_brokers: kafka_broker
)
data = JSON.parse(File.read("iris.json"))

producer = kafka.producer
data.each do |h|
  producer.produce(JSON.dump(h), topic: kafka_topic)
end
producer.deliver_messages
```
